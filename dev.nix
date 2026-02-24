{ pkgs, ... }:

{
  # Módulos de IDX para configurar el entorno
  imports = [
    # Habilitar el servicio de PostgreSQL
    # Documentación: https://devenv.sh/services/postgresql/
    ./.idx/dev.nix
    { services.postgresql.enable = true; }
  ];

  # Paquetes disponibles en el entorno
  # Documentación: https://devenv.sh/packages/
  packages = [ pkgs.git ];

  # Variables de entorno
  # Documentación: https://devenv.sh/options/#envname-value
  env.GREET = "Hello from dev.nix!";

  # Comandos que se ejecutan al iniciar el shell
  # Documentación: https://devenv.sh/hooks/
  enterShell = ''
    hello
    git --version
  '';

  # Scripts personalizados
  # Documentación: https://devenv.sh/scripts/
  scripts.hello.exec = "echo $GREET";
}