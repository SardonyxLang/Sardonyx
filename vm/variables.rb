class Variable 
    @mut = false
    attr_reader :type, :value, :scope

    def initialize(val=nil, type=nil, scope=nil)
        @value = val
        @type = type
        @scope = scope
    end

    def set(val)
        if @mut == true 
            @value = val
        else
            puts "cant change value of immutable" # add error handling
        end
    end
end

