# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

pin "channels", integrity: "sha384-JDCq3YicVZ74RumoxFRPD4Cc5e7Lci4MORL5EDX2YFbwRysdyJqbItOP8fTvwXfa" # @0.0.4
pin "domain", integrity: "sha384-NISHQRRiQNj/zfyRtvvB+6MHzmjfs7Nk5nxqEbIkNoKVb9iP2wvLGAj9iGf5mv/D" # @2.1.0
pin "@rails/actioncable", to: "@rails--actioncable.js", integrity: "sha384-J9kCXP+j3uFXQw6/pfAdLmqYNZ019ggd096Lebw+1crESHJvLM3wRMOF+il4u0Gp" # @8.0.200
