{
  dotfiles.nixos = {config, lib, ...}: {
    options.dotfiles.hardware.nvidia.enable = lib.mkEnableOption "Nvidia";
    config = lib.mkIf config.dotfiles.hardware.nvidia.enable {
      hardware.nvidia = {
        modesetting.enable = true;
        open = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        powerManagement.enable = true;
      };
      nixpkgs.config.cudaSupport = true;
      dotfiles.nixpkgs.config.allowUnfreePackages = [
        "cuda_cccl"
        "cuda_cudart"
        "cuda_nvcc"
        "libcublas"
        "nvidia-x11"
        "nvidia-settings"
        "nvidia-persistenced"
      ];
      services.xserver.videoDrivers = ["nvidia"];
    };
  };
}
