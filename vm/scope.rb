class GLOBAL_SCOPE
    attr_reader :variables

    def error(msg)
        puts "\x1b[0;31mError in VM: #{msg}\x1b[0;0m"
        exit 1
    end

    def initialize(variables={})
        @variables = variables
    end

    def add_var(var_name, var_class)
        @variables[var_name] = var_class
    end

    def add_fn(fn_name, fn_class)
        @variables[fn_name] = fn_class
    end

    def get_var(var_name)
        scope = self
        val = nil
        name = var_name.split "."
        name.each do |part|
            val = scope.variables[part]
            unless val
                error "No such variable #{part}"
            end
            case val.value
            when InstantiatedObj
                scope = val.value.internal
            else
                fields = {}
                if val.value.respond_to? :fields
                    val.value.fields.each do |k, v|
                        fields[k] = Variable.new v
                    end
                    scope = GLOBAL_SCOPE.new fields
                end
            end
        end
        return val
    end

    def get_fn(fn_name)
        @variables[fn_name]
    end

    def add_obj(obj_name, obj_class)
        if obj_class.value.args.size == 0
            scope = obj_class.value.fields["__new"].call [], self
            scope.variables.each do |k, v|
                add_var "#{obj_name}:#{k}", scope.variables[k]
            end
        else
            @variables[obj_name] = obj_class
        end
    end
end