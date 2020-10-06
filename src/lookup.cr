require "./error"

module SDX
    module Lookup
        def self.warn
            unless ENV.fetch("SDX_PATH", "") != ""
                puts "\x1b[33mYou have nothing in your SDX_PATH! Try installing SardonyxStd with Volcano.\x1b[0m"
            end
        end

        def self.lookup(path : String)
            env = ENV["SDX_PATH"].split ":"
            if File.exists? File.expand_path("#{path}.sdx")
                File.expand_path("#{path}.sdx")
            else
                env.each do |part|
                    if File.exists? File.expand_path(File.join(part, "#{path}.sdx"))
                        return File.expand_path(File.join(part, "#{path}.sdx"))
                    end
                end
                Error.lookup_error "Could not find file #{File.basename path}.sdx anywhere"
                return nil
            end
        end
    end
end