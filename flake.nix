{
  description = "Virtual machine build environment with all required dependencies";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        pythonEnv = pkgs.python3.withPackages (ps: with ps; [
          pip
          passlib
          setuptools
          wheel
          requests
          urllib3
        ]);

        # Custom script to install Python packages not in nixpkgs
        setupPythonPackages = pkgs.writeShellScriptBin "setup-python-packages" ''
          echo "Installing Python packages not available in nixpkgs..."
          if [ ! -d ".venv" ]; then
            echo "Creating virtual environment..."
            python -m venv .venv
          fi
          echo "Activating virtual environment..."
          source .venv/bin/activate
          pip install python-openstackclient s3cmd
          echo "Python packages installed successfully"
          echo "Virtual environment created at .venv - activate with 'source .venv/bin/activate'"
        '';

        # Script to download and setup allas configuration
        setupAllas = pkgs.writeShellScriptBin "setup-allas" ''
          echo "Downloading allas configuration script..."
          if [ ! -f allas_conf ]; then
            wget https://raw.githubusercontent.com/CSCfi/allas-cli-utils/master/allas_conf
            chmod +x allas_conf
          fi
          echo "Allas configuration downloaded. Run 'source allas_conf --mode S3 --user your-csc-username' to configure."
        '';

        # Script to initialize packer
        initPacker = pkgs.writeShellScriptBin "init-packer" ''
          echo "Initializing Packer..."
          if [ -f packer_phase1.pkr.hcl ]; then
            packer init packer_phase1.pkr.hcl
            echo "Packer initialized successfully"
          else
            echo "packer_phase1.pkr.hcl not found in current directory"
          fi
        '';

        # Complete setup script
        vmsSetup = pkgs.writeShellScriptBin "vms-setup" ''
          echo "Installing Ansible collections..."
          ansible-galaxy collection install community.general

          ${setupPythonPackages}/bin/setup-python-packages
          ${setupAllas}/bin/setup-allas
          ${initPacker}/bin/init-packer

          echo ""
          echo "Virtual machine build environment setup complete!"
          echo ""
          echo "Available commands:"
          echo "  - packer: Infrastructure as code tool"
          echo "  - ansible: Configuration management"
          echo "  - qemu-system-x86_64: Virtualization"
          echo "  - restic: Backup tool"
          echo "  - rclone: Cloud storage sync"
          echo "  - setup-python-packages: Install additional Python packages"
          echo "  - setup-allas: Download allas configuration"
          echo "  - init-packer: Initialize Packer configuration"
          echo ""
          echo "To configure allas, run: source allas_conf --mode S3 --user your-csc-username"
        '';

      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [

            # Infrastructure tools
            packer
            ansible
            qemu

            # Backup and storage tools
            restic
            rclone

            # Python environment
            pythonEnv

            # Custom setup scripts
            setupPythonPackages
            setupAllas
            initPacker
            vmsSetup
          ];

          shellHook = ''
            echo "Virtual machine build environment"
            echo "=============================="
            echo ""
            echo "This environment includes:"
            echo "  - Packer ($(packer version | head -1))"
            echo "  - Ansible ($(ansible --version | head -1))"
            echo "  - QEMU ($(qemu-system-x86_64 --version | head -1))"
            echo "  - Python $(python --version | cut -d' ' -f2) with pip"
            echo "  - Restic $(restic version | head -1)"
            echo "  - Rclone $(rclone version | head -1 | cut -d' ' -f2)"
            echo ""
            echo "To complete setup, run: vms-setup"
            echo ""
            if [ -d ".venv" ]; then
              echo "Python virtual environment available at .venv"
              echo "Activate with: source .venv/bin/activate"
              echo ""
            fi
            echo "For help, check available commands with 'which vms-setup'"
          '';

          # Environment variables
          ANSIBLE_HOST_KEY_CHECKING = "False";
          PYTHONPATH = "${pythonEnv}/${pythonEnv.sitePackages}";
        };

        # Apps for easy running
        apps = {
          setup = flake-utils.lib.mkApp {
            drv = vmsSetup;
          };

          packer-init = flake-utils.lib.mkApp {
            drv = initPacker;
          };

          allas-setup = flake-utils.lib.mkApp {
            drv = setupAllas;
          };
        };
      });
}
