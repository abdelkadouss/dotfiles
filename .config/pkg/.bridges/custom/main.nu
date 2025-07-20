use ../../.api/bridges.nu *;

bridge new {
  info: {
    name: "custom",
    description: "custom installation scripts",
    version: "0.1.0",
  },
  config: {
    env: {
      source_dir: "/Users/abdelkdous/.config/pkg"
    }
    isolate_path: true
    executables: [
      nu
    ],
  },
  usege: {
    install: {
      script: {|pkg:string|
        let script = (
          [
            $env.source_dir
            ".lib/custom"
            $"($pkg).nu"
          ] | path join
        );

        if ($script | path exists) {
          nu $script

        } else {
          panic "script not found"

        }

      },
    }
    remove: { },
    update: { },
    cleanup: {
      events: [ "AFTER_INSTALL", "AFTER_UPDATE" ],
    },
  },
}
