Gem::Specification.new do |s|
    s.name = 'sardonyx'
    s.version = '0.2.1'
    s.files = [
        'lib/sdx/vm/datatypes.rb', 
        'lib/sdx/vm/scope.rb', 
        'lib/sdx/vm/variables.rb', 
        'lib/sdx/vm/vm.rb', 
        'lib/sdx/compiler/parser.rb', 
        'lib/sdx/compiler/compiler.rb'
    ]
    s.executables << 'sdx'
    s.date = '2020-08-25'
    s.summary = 'Sardonyx Language'
    s.description = 'The Sardonyx programming language'
    s.authors = ['sugarfi', 'Zavexeon']
    s.email = 'sugarfi@sugarfi.dev'
    s.homepage = 'https://sardonyxlang.github.io'
    s.license = 'MIT'
end
