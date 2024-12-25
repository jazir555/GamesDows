import os
import subprocess
import shutil
import argparse
from pathlib import Path
import sys
import time
import PyInstaller
import atexit
import requests
import psutil
import re

class DeckyBuilder:
    def __init__(self, release: str = None):
        self.release = release or self.prompt_for_version()
        self.root_dir = Path(__file__).resolve().parent
        self.app_dir = self.root_dir / "app"
        self.src_dir = self.root_dir / "src"
        self.dist_dir = self.root_dir / "dist"
        self.homebrew_dir = self.dist_dir / "homebrew"
        self.temp_files = []  # Track temporary files for cleanup
        atexit.register(self.cleanup)  # Register cleanup on exit
        
        # Setup user homebrew directory
        self.user_home = Path.home()
        self.user_homebrew_dir = self.user_home / "homebrew"
        self.homebrew_folders = [
            "data",
            "logs",
            "plugins",
            "services",
            "settings",
            "themes"
        ]

    def cleanup(self):
        """Clean up temporary files and directories"""
        try:
            # Clean up any temporary files we created
            for temp_file in self.temp_files:
                if os.path.exists(temp_file):
                    try:
                        if os.path.isfile(temp_file):
                            os.remove(temp_file)
                        elif os.path.isdir(temp_file):
                            shutil.rmtree(temp_file, ignore_errors=True)
                    except Exception as e:
                        print(f"Warning: Failed to remove temporary file {temp_file}: {e}")

            # Clean up PyInstaller temp files
            for dir_name in ['build', 'dist']:
                dir_path = self.root_dir / dir_name
                if dir_path.exists():
                    try:
                        shutil.rmtree(dir_path, ignore_errors=True)
                    except Exception as e:
                        print(f"Warning: Failed to remove {dir_name} directory: {e}")

            # Clean up PyInstaller spec files
            for spec_file in self.root_dir.glob("*.spec"):
                try:
                    os.remove(spec_file)
                except Exception as e:
                    print(f"Warning: Failed to remove spec file {spec_file}: {e}")

        except Exception as e:
            print(f"Warning: Error during cleanup: {e}")

    def safe_remove_directory(self, path):
        """Safely remove a directory with retries for Windows"""
        max_retries = 3
        retry_delay = 1  # seconds

        for attempt in range(max_retries):
            try:
                if path.exists():
                    # On Windows, sometimes we need to remove .git directory separately
                    git_dir = path / '.git'
                    if git_dir.exists():
                        for item in git_dir.glob('**/*'):
                            if item.is_file():
                                try:
                                    item.chmod(0o777)  # Give full permissions
                                    item.unlink()
                                except:
                                    pass
                    
                    shutil.rmtree(path, ignore_errors=True)
                return
            except Exception as e:
                print(f"Attempt {attempt + 1} failed to remove {path}: {str(e)}")
                if attempt < max_retries - 1:
                    time.sleep(retry_delay)
                    continue
                else:
                    print(f"Warning: Could not fully remove {path}. Continuing anyway...")

    def setup_directories(self):
        """Setup directory structure"""
        print("Setting up directories...")
        # Clean up any existing directories
        if self.app_dir.exists():
            self.safe_remove_directory(self.app_dir)
        if self.src_dir.exists():
            self.safe_remove_directory(self.src_dir)
        if self.homebrew_dir.exists():
            self.safe_remove_directory(self.homebrew_dir)

        # Create fresh directories
        self.src_dir.mkdir(parents=True, exist_ok=True)
        self.homebrew_dir.mkdir(parents=True, exist_ok=True)

    def setup_homebrew(self):
        """Setup homebrew directory structure"""
        print("Setting up homebrew directory structure...")
        # Create dist directory
        (self.homebrew_dir / "dist").mkdir(parents=True, exist_ok=True)

        # Setup homebrew directory structure for both temp and user directories
        print("Setting up homebrew directory structure...")
        for directory in [self.homebrew_dir, self.user_homebrew_dir]:
            if not directory.exists():
                directory.mkdir(parents=True)
            
            for folder in self.homebrew_folders:
                folder_path = directory / folder
                if not folder_path.exists():
                    folder_path.mkdir(parents=True)

    def clone_repository(self):
        """Clone Decky Loader repository and checkout specific version"""
        print(f"\nCloning Decky Loader repository version: {self.release}")
        
        # Clean up existing directory
        if os.path.exists(self.app_dir):
            print("Removing existing repository...")
            self.safe_remove_directory(self.app_dir)
        
        try:
            # Clone the repository
            subprocess.run([
                'git', 'clone', '--no-checkout',  # Don't checkout anything yet
                'https://github.com/SteamDeckHomebrew/decky-loader.git',
                str(self.app_dir)
            ], check=True)
            
            os.chdir(self.app_dir)
            
            # Fetch all refs
            subprocess.run(['git', 'fetch', '--all', '--tags'], check=True)
            
            # Try to checkout the exact version first
            try:
                subprocess.run(['git', 'checkout', self.release], check=True)
            except subprocess.CalledProcessError:
                # If exact version fails, try to find the commit for pre-releases
                if '-pre' in self.release:
                    # Get all tags and their commit hashes
                    result = subprocess.run(
                        ['git', 'ls-remote', '--tags', 'origin'],
                        capture_output=True, text=True, check=True
                    )
                    
                    # Find the commit hash for our version
                    for line in result.stdout.splitlines():
                        commit_hash, ref = line.split('\t')
                        ref = ref.replace('refs/tags/', '')
                        ref = ref.replace('^{}', '')  # Remove annotated tag suffix
                        if ref == self.release:
                            print(f"Found commit {commit_hash} for version {self.release}")
                            subprocess.run(['git', 'checkout', commit_hash], check=True)
                            break
                    else:
                        raise Exception(f"Could not find commit for version {self.release}")
                else:
                    raise
            
            print(f"Successfully checked out version: {self.release}")
            
            # Create version files in key locations with the requested version
            version_files = [
                '.loader.version',
                'frontend/.loader.version',
                'backend/.loader.version',
                'backend/decky_loader/.loader.version'
            ]
            
            for version_file in version_files:
                file_path = os.path.join(self.app_dir, version_file)
                os.makedirs(os.path.dirname(file_path), exist_ok=True)
                with open(file_path, 'w') as f:
                    f.write(self.release)  # Use the requested version
            
        except subprocess.CalledProcessError as e:
            raise Exception(f"Failed to clone/checkout repository: {str(e)}")
        finally:
            os.chdir(self.root_dir)

    def build_frontend(self):
        """Build frontend files"""
        print("Building frontend...")
        batch_file = None
        original_dir = os.getcwd()
        
        try:
            frontend_dir = self.app_dir / "frontend"
            if not frontend_dir.exists():
                raise Exception(f"Frontend directory not found at {frontend_dir}")

            print(f"Changing to frontend directory: {frontend_dir}")
            os.chdir(frontend_dir)

            # Create .loader.version file with the release tag
            version_file = frontend_dir / ".loader.version"
            with open(version_file, "w") as f:
                f.write(self.release)
            self.temp_files.append(str(version_file))

            # Create a batch file to run the commands
            batch_file = frontend_dir / "build_frontend.bat"
            with open(batch_file, "w") as f:
                f.write("@echo off\n")
                f.write("call pnpm install\n")
                f.write("if %errorlevel% neq 0 exit /b %errorlevel%\n")
                f.write("call pnpm run build\n")
                f.write("if %errorlevel% neq 0 exit /b %errorlevel%\n")
            self.temp_files.append(str(batch_file))

            print("Running build commands...")
            result = subprocess.run([str(batch_file)], check=True, capture_output=True, text=True, shell=True)
            print(result.stdout)

        except subprocess.CalledProcessError as e:
            print(f"Command failed: {e.cmd}")
            print(f"Output: {e.output}")
            print(f"Error: {e.stderr}")
            raise Exception(f"Error building frontend: Command failed - {str(e)}")
        except Exception as e:
            print(f"Error building frontend: {str(e)}")
            raise
        finally:
            # Always return to original directory
            os.chdir(original_dir)

    def prepare_backend(self):
        """Prepare backend files for building."""
        print("Preparing backend files...")
        print("Copying files according to Dockerfile structure...")

        # Create src directory if it doesn't exist
        os.makedirs(self.src_dir, exist_ok=True)

        # Copy backend files from app/backend/decky_loader to src/decky_loader
        print("Copying backend files...")
        shutil.copytree(os.path.join(self.app_dir, "backend", "decky_loader"), 
                       os.path.join(self.src_dir, "decky_loader"), 
                       dirs_exist_ok=True)

        # Copy static, locales, and plugin directories to maintain decky_loader structure
        os.makedirs(os.path.join(self.src_dir, "decky_loader"), exist_ok=True)
        shutil.copytree(os.path.join(self.app_dir, "backend", "decky_loader", "static"),
                       os.path.join(self.src_dir, "decky_loader", "static"),
                       dirs_exist_ok=True)
        shutil.copytree(os.path.join(self.app_dir, "backend", "decky_loader", "locales"),
                       os.path.join(self.src_dir, "decky_loader", "locales"),
                       dirs_exist_ok=True)
        shutil.copytree(os.path.join(self.app_dir, "backend", "decky_loader", "plugin"),
                       os.path.join(self.src_dir, "decky_loader", "plugin"),
                       dirs_exist_ok=True)

        # Create legacy directory
        os.makedirs(os.path.join(self.src_dir, "src", "legacy"), exist_ok=True)

        # Copy main.py to src directory
        shutil.copy2(os.path.join(self.app_dir, "backend", "main.py"),
                    os.path.join(self.src_dir, "main.py"))

        # Create version file in the src directory
        version_file = os.path.join(self.src_dir, ".loader.version")
        with open(version_file, "w") as f:
            f.write(self.release)

        print("Backend preparation completed successfully!")
        return True

    def install_requirements(self):
        """Install Python requirements"""
        print("Installing Python requirements...")
        try:
            # Try both requirements.txt and pyproject.toml
            requirements_file = self.app_dir / "backend" / "requirements.txt"
            pyproject_file = self.app_dir / "backend" / "pyproject.toml"
            
            if requirements_file.exists():
                subprocess.run([
                    sys.executable, "-m", "pip", "install", "--user", "-r", str(requirements_file)
                ], check=True)
            elif pyproject_file.exists():
                # Install core dependencies directly instead of using poetry
                dependencies = [
                    "aiohttp>=3.8.1",
                    "psutil>=5.9.0",
                    "fastapi>=0.78.0",
                    "uvicorn>=0.17.6",
                    "python-multipart>=0.0.5",
                    "watchdog>=2.1.7",
                    "requests>=2.27.1",
                    "setuptools>=60.0.0",
                    "wheel>=0.37.1",
                    "winregistry>=1.1.1; platform_system == 'Windows'",
                    "pywin32>=303; platform_system == 'Windows'"
                ]
                
                # Install each dependency
                for dep in dependencies:
                    try:
                        subprocess.run([
                            sys.executable, "-m", "pip", "install", "--user", dep
                        ], check=True)
                    except subprocess.CalledProcessError as e:
                        print(f"Warning: Failed to install {dep}: {str(e)}")
                        continue
            else:
                print("Warning: No requirements.txt or pyproject.toml found")
        except Exception as e:
            print(f"Error installing requirements: {str(e)}")
            raise

    def add_defender_exclusion(self, path):
        """Add Windows Defender exclusion for a path"""
        try:
            subprocess.run([
                "powershell",
                "-Command",
                f"Add-MpPreference -ExclusionPath '{path}'"
            ], check=True, capture_output=True)
            return True
        except:
            print("Warning: Could not add Windows Defender exclusion. You may need to run as administrator or manually add an exclusion.")
            return False

    def remove_defender_exclusion(self, path):
        """Remove Windows Defender exclusion for a path"""
        try:
            subprocess.run([
                "powershell",
                "-Command",
                f"Remove-MpPreference -ExclusionPath '{path}'"
            ], check=True, capture_output=True)
        except:
            print("Warning: Could not remove Windows Defender exclusion.")

    def build_executables(self):
        """Build executables using PyInstaller"""
        print("\nBuilding executables...")
        
        # Read version from .loader.version
        version_file = os.path.join(self.app_dir, '.loader.version')
        if not os.path.exists(version_file):
            raise Exception("Version file not found. Run clone_repository first.")
            
        with open(version_file, 'r') as f:
            version = f.read().strip()
            
        # Normalize version for Python packaging
        # Convert v3.0.5-pre1 to 3.0.5rc1
        py_version = version.lstrip('v')  # Remove v prefix
        if '-pre' in py_version:
            py_version = py_version.replace('-pre', 'rc')
            
        print(f"Building version: {version} (Python package version: {py_version})")
        
        original_dir = os.getcwd()
        backend_dir = os.path.join(self.app_dir, "backend")
        dist_dir = os.path.join(backend_dir, "dist")
        
        # Add Windows Defender exclusion for build directories
        added_exclusion = self.add_defender_exclusion(backend_dir)
        
        try:
            os.chdir(backend_dir)
            
            # Create setup.py with the correct version
            setup_py = """
            from setuptools import setup, find_packages
            
            setup(
                name="decky_loader",
                version="%s",
                packages=find_packages(),
                package_data={
                    'decky_loader': [
                        'locales/*',
                        'static/*',
                        '.loader.version'
                    ],
                },
                install_requires=[
                    'aiohttp>=3.8.1',
                    'certifi>=2022.6.15',
                    'packaging>=21.3',
                    'psutil>=5.9.1',
                    'requests>=2.28.1',
                ],
            )
            """ % py_version

            with open("setup.py", "w") as f:
                f.write(setup_py)
                
            # Install the package in development mode
            subprocess.run([sys.executable, "-m", "pip", "install", "-e", "."], check=True)
            
            # Common PyInstaller arguments
            pyinstaller_args = [
                sys.executable,
                "-m",
                "PyInstaller",
                "--clean",
                "--noconfirm",
                "pyinstaller.spec"
            ]
            
            # First build console version
            print("Building PluginLoader.exe (console version)...")
            os.environ.pop('DECKY_NOCONSOLE', None)  # Ensure env var is not set
            subprocess.run(pyinstaller_args, check=True)
            
            # Then build no-console version
            print("Building PluginLoader_noconsole.exe...")
            os.environ['DECKY_NOCONSOLE'] = '1'
            subprocess.run(pyinstaller_args, check=True)
            
            # Clean up environment
            os.environ.pop('DECKY_NOCONSOLE', None)
            
            # Copy the built executables to dist
            os.makedirs(os.path.join(self.root_dir, "dist"), exist_ok=True)
            if os.path.exists(os.path.join("dist", "PluginLoader.exe")):
                shutil.copy2(
                    os.path.join("dist", "PluginLoader.exe"),
                    os.path.join(self.root_dir, "dist", "PluginLoader.exe")
                )
            else:
                raise Exception("PluginLoader.exe not found after build")
                
            if os.path.exists(os.path.join("dist", "PluginLoader_noconsole.exe")):
                shutil.copy2(
                    os.path.join("dist", "PluginLoader_noconsole.exe"),
                    os.path.join(self.root_dir, "dist", "PluginLoader_noconsole.exe")
                )
            else:
                raise Exception("PluginLoader_noconsole.exe not found after build")
                
            print("Successfully built executables")
            
        except subprocess.CalledProcessError as e:
            raise Exception(f"Failed to build executables: {str(e)}")
        finally:
            if added_exclusion:
                self.remove_defender_exclusion(backend_dir)
            os.chdir(original_dir)

    def install_files(self):
        """Install files to homebrew directory"""
        print("\nInstalling files to homebrew directory...")
        
        # Create homebrew directory if it doesn't exist
        homebrew_dir = os.path.join(os.path.expanduser("~"), "homebrew")
        services_dir = os.path.join(homebrew_dir, "services")
        os.makedirs(services_dir, exist_ok=True)
        
        try:
            # Copy PluginLoader.exe and PluginLoader_noconsole.exe
            for exe_name in ["PluginLoader.exe", "PluginLoader_noconsole.exe"]:
                exe_source = os.path.join(self.root_dir, "dist", exe_name)
                exe_dest = os.path.join(services_dir, exe_name)
                if not os.path.exists(exe_source):
                    raise Exception(f"{exe_name} not found at {exe_source}")
                shutil.copy2(exe_source, exe_dest)
            
            # Create .loader.version file
            version_file = os.path.join(services_dir, ".loader.version")
            with open(version_file, "w") as f:
                f.write(self.release)
            
            print("Successfully installed files")
            
        except Exception as e:
            raise Exception(f"Failed to copy files to homebrew: {str(e)}")

    def install_nodejs(self):
        """Install Node.js v18.18.0 with npm"""
        print("Installing Node.js v18.18.0...")
        try:
            # First check if Node.js v18.18.0 is already installed in common locations
            nodejs_paths = [
                r"C:\Program Files\nodejs\node.exe",
                r"C:\Program Files (x86)\nodejs\node.exe",
                os.path.expandvars(r"%APPDATA%\Local\Programs\nodejs\node.exe")
            ]

            # Try to use existing Node.js 18.18.0 first
            for node_path in nodejs_paths:
                if os.path.exists(node_path):
                    try:
                        version = subprocess.run([node_path, "--version"], capture_output=True, text=True).stdout.strip()
                        if version.startswith("v18.18.0"):
                            print(f"Found Node.js {version} at {node_path}")
                            node_dir = os.path.dirname(node_path)
                            if node_dir not in os.environ["PATH"]:
                                os.environ["PATH"] = node_dir + os.pathsep + os.environ["PATH"]
                            return True
                    except:
                        continue

            # If we get here, we need to install Node.js 18.18.0
            print("Installing Node.js v18.18.0...")
            
            # Create temp directory for downloads
            temp_dir = self.root_dir / "temp"
            temp_dir.mkdir(exist_ok=True)
            
            # Download Node.js installer
            node_installer = temp_dir / "node-v18.18.0-x64.msi"
            if not node_installer.exists():
                print("Downloading Node.js installer...")
                try:
                    import urllib.request
                    urllib.request.urlretrieve(
                        "https://nodejs.org/dist/v18.18.0/node-v18.18.0-x64.msi",
                        node_installer
                    )
                except Exception as e:
                    print(f"Error downloading Node.js installer: {str(e)}")
                    raise

            # Install Node.js silently
            print("Installing Node.js (this may take a few minutes)...")
            try:
                # First try to uninstall any existing Node.js using PowerShell
                uninstall_cmd = 'Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*Node.js*" } | ForEach-Object { $_.Uninstall() }'
                subprocess.run(["powershell", "-Command", uninstall_cmd], capture_output=True, timeout=60)
                
                # Wait a bit for uninstallation to complete
                time.sleep(5)
                
                # Now install Node.js 18.18.0
                subprocess.run(
                    ["msiexec", "/i", str(node_installer), "/qn", "ADDLOCAL=ALL"],
                    check=True,
                    timeout=300  # 5 minute timeout
                )
                
                print("Waiting for Node.js installation to complete...")
                time.sleep(10)
                
                # Add to PATH
                nodejs_path = r"C:\Program Files\nodejs"
                npm_path = os.path.join(os.environ["APPDATA"], "npm")
                
                # Update PATH for current process
                if nodejs_path not in os.environ["PATH"]:
                    os.environ["PATH"] = nodejs_path + os.pathsep + os.environ["PATH"]
                if npm_path not in os.environ["PATH"]:
                    os.environ["PATH"] = npm_path + os.pathsep + os.environ["PATH"]
                
                # Verify installation
                node_version = subprocess.run(["node", "--version"], capture_output=True, text=True, check=True).stdout.strip()
                if not node_version.startswith("v18.18.0"):
                    raise Exception(f"Wrong Node.js version installed: {node_version}")
                
                npm_version = subprocess.run(["npm", "--version"], capture_output=True, text=True, check=True).stdout.strip()
                print(f"Successfully installed Node.js {node_version} with npm {npm_version}")
                
                # Clean up
                self.safe_remove_directory(temp_dir)
                return True
                
            except subprocess.TimeoutExpired:
                print("Installation timed out. Please try installing Node.js v18.18.0 manually.")
                raise
            except Exception as e:
                print(f"Installation failed: {str(e)}")
                raise
            
        except Exception as e:
            print(f"Error installing Node.js: {str(e)}")
            raise

    def setup_steam_config(self):
        """Configure Steam for Decky Loader"""
        print("Configuring Steam...")
        try:
            # Add -dev argument to Steam shortcut
            import winreg
            steam_path = None
            
            # Try to find Steam installation path from registry
            try:
                with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\WOW6432Node\Valve\Steam") as key:
                    steam_path = winreg.QueryValueEx(key, "InstallPath")[0]
            except:
                try:
                    with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Valve\Steam") as key:
                        steam_path = winreg.QueryValueEx(key, "InstallPath")[0]
                except:
                    print("Steam installation not found in registry")
            
            if steam_path:
                steam_exe = Path(steam_path) / "steam.exe"
                if steam_exe.exists():
                    # Create .cef-enable-remote-debugging file
                    debug_file = Path(steam_path) / ".cef-enable-remote-debugging"
                    debug_file.touch()
                    print("Created .cef-enable-remote-debugging file")
                    
                    # Create/modify Steam shortcut
                    desktop = Path.home() / "Desktop"
                    shortcut_path = desktop / "Steam.lnk"
                    
                    import pythoncom
                    from win32com.client import Dispatch
                    
                    shell = Dispatch("WScript.Shell")
                    shortcut = shell.CreateShortCut(str(shortcut_path))
                    shortcut.Targetpath = str(steam_exe)
                    shortcut.Arguments = "-dev"
                    shortcut.save()
                    print("Created Steam shortcut with -dev argument")

        except Exception as e:
            print(f"Error configuring Steam: {str(e)}")
            raise

    def setup_autostart(self):
        """Setup PluginLoader to run at startup"""
        print("Setting up autostart...")
        try:
            # Get the path to the no-console executable
            services_dir = os.path.join(os.path.expanduser("~"), "homebrew", "services")
            plugin_loader = os.path.join(services_dir, "PluginLoader_noconsole.exe")

            # Get the Windows Startup folder path
            startup_folder = os.path.join(os.environ["APPDATA"], "Microsoft", "Windows", "Start Menu", "Programs", "Startup")
            
            # Create a batch file in the startup folder
            startup_bat = os.path.join(startup_folder, "start_decky.bat")
            
            # Write the batch file with proper path escaping
            with open(startup_bat, "w") as f:
                f.write(f'@echo off\n"{plugin_loader}"')

            print(f"Created startup script at: {startup_bat}")
            return True

        except Exception as e:
            print(f"Error setting up autostart: {str(e)}")
            return False

    def check_python_version(self):
        """Check if correct Python version is being used"""
        print("Checking Python version...")
        if sys.version_info.major != 3 or sys.version_info.minor != 11:
            raise Exception("This script requires Python 3.11. Please run using decky_builder.bat")

    def check_dependencies(self):
        """Check and install required dependencies"""
        print("Checking dependencies...")
        try:
            # Check Node.js and npm first
            try:
                # Use shell=True to find node in PATH
                node_version = subprocess.run("node --version", shell=True, check=True, capture_output=True, text=True).stdout.strip()
                npm_version = subprocess.run("npm --version", shell=True, check=True, capture_output=True, text=True).stdout.strip()
                
                # Check if version meets requirements
                if not node_version.startswith("v18."):
                    print(f"Node.js {node_version} found, but v18.18.0 is required")
                    self.install_nodejs()
                else:
                    print(f"Node.js {node_version} with npm {npm_version} is installed")

            except Exception as e:
                print(f"Node.js/npm not found or error: {str(e)}")
                self.install_nodejs()

            # Install pnpm globally if not present
            try:
                pnpm_version = subprocess.run("pnpm --version", shell=True, check=True, capture_output=True, text=True).stdout.strip()
                print(f"pnpm version {pnpm_version} is installed")
            except:
                print("Installing pnpm globally...")
                subprocess.run("npm i -g pnpm", shell=True, check=True)
                pnpm_version = subprocess.run("pnpm --version", shell=True, check=True, capture_output=True, text=True).stdout.strip()
                print(f"Installed pnpm version {pnpm_version}")

            # Check git
            try:
                git_version = subprocess.run("git --version", shell=True, check=True, capture_output=True, text=True).stdout.strip()
                print(f"{git_version} is installed")
            except:
                raise Exception("git is not installed. Please install git from https://git-scm.com/downloads")

            print("All dependencies are satisfied")
        except Exception as e:
            print(f"Error checking dependencies: {str(e)}")
            raise

    def get_release_versions(self):
        """Get list of available release versions"""
        print("Fetching available versions...")
        try:
            response = requests.get(
                "https://api.github.com/repos/SteamDeckHomebrew/decky-loader/releases"
            )
            response.raise_for_status()
            releases = response.json()
            
            # Split releases into stable and pre-release
            stable_releases = []
            pre_releases = []
            
            for release in releases:
                version = release['tag_name']
                if release['prerelease']:
                    pre_releases.append(version)
                else:
                    stable_releases.append(version)
            
            # Sort versions and take only the latest 3 of each
            stable_releases.sort(reverse=True)
            pre_releases.sort(reverse=True)
            
            stable_releases = stable_releases[:3]
            pre_releases = pre_releases[:3]
            
            # Combine and sort all versions
            all_versions = stable_releases + pre_releases
            all_versions.sort(reverse=True)
            
            return all_versions
            
        except requests.RequestException as e:
            raise Exception(f"Failed to fetch release versions: {str(e)}")

    def prompt_for_version(self):
        """Prompt the user to select a version to install."""
        versions = self.get_release_versions()
        
        print("\nAvailable versions:")
        print("Stable versions:")
        stable_count = 0
        for i, version in enumerate(versions):
            if '-pre' not in version:
                print(f"{i+1}. {version}")
                stable_count += 1
        
        print("\nPre-release versions:")
        for i, version in enumerate(versions):
            if '-pre' in version:
                print(f"{i+1}. {version}")
        
        while True:
            try:
                choice = input("\nSelect a version (1-{}): ".format(len(versions)))
                index = int(choice) - 1
                if 0 <= index < len(versions):
                    return versions[index]
                print("Invalid selection, please try again.")
            except ValueError:
                print("Invalid input, please enter a number.")

    def terminate_processes(self):
        """Terminate running instances of executables that may interfere with the build."""
        for proc in psutil.process_iter(['pid', 'name', 'exe']):
            if proc.info['name'] in ['PluginLoader.exe', 'PluginLoader_noconsole.exe']:
                try:
                    proc.terminate()
                    proc.wait()
                except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
                    pass

    def run(self):
        """Run the build and installation process."""
        # Terminate interfering processes
        self.terminate_processes()
        try:
            print("Starting Decky Loader build process...")
            self.check_python_version()
            self.check_dependencies()
            self.setup_directories()
            self.clone_repository()
            self.setup_homebrew()
            self.build_frontend()
            self.prepare_backend()
            self.install_requirements()
            self.build_executables()
            self.install_files()
            self.setup_steam_config()
            self.setup_autostart()
            print("\nBuild process completed successfully!")
            print("\nNext steps:")
            print("1. Close Steam if it's running")
            print("2. Launch Steam using the new shortcut on your desktop")
            print("3. Enter Big Picture Mode")
            print("4. Hold the STEAM button and press A to access the Decky menu")
        except Exception as e:
            print(f"Error during build process: {str(e)}")
            raise
        finally:
            self.cleanup()

def main():
    parser = argparse.ArgumentParser(description='Build and Install Decky Loader for Windows')
    parser.add_argument('--release', required=False, default=None, 
                      help='Release version/branch to build (if not specified, will prompt for version)')
    args = parser.parse_args()

    try:
        builder = DeckyBuilder(args.release)
        builder.run()
        print(f"\nDecky Loader has been installed to: {builder.user_homebrew_dir}")
    except Exception as e:
        print(f"Error during build process: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main()
