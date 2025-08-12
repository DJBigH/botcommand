# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "@rails/actioncable", to: "@rails--actioncable.js", integrity: "sha384-J9kCXP+j3uFXQw6/pfAdLmqYNZ019ggd096Lebw+1crESHJvLM3wRMOF+il4u0Gp" # @8.0.200

