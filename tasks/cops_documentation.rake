# frozen_string_literal: true

require 'yard'
require 'rubocop'
require 'rubocop-performance'
require 'rubocop/cops_documentation_generator'

YARD::Rake::YardocTask.new(:yard_for_generate_documentation) do |task|
  task.files = ['lib/rubocop/cop/**/*.rb']
  task.options = ['--no-output']
end

task update_cops_documentation: :yard_for_generate_documentation do
  deps = ['Performance']

  # NOTE: Update `<<next>>` version for docs/modules/ROOT/pages/cops_performance.adoc
  # when running release tasks.
  CopsDocumentationGenerator.new(departments: deps, plugin_name: 'rubocop-performance').call
end

desc 'Syntax check for the documentation comments'
task documentation_syntax_check: :yard_for_generate_documentation do
  require 'parser/ruby32'

  ok = true
  YARD::Registry.load!
  cops = RuboCop::Cop::Registry.global
  cops.each do |cop|
    examples = YARD::Registry.all(:class).find do |code_object|
      next unless RuboCop::Cop::Badge.for(code_object.to_s) == cop.badge

      break code_object.tags('example')
    end

    examples.to_a.each do |example|
      buffer = Parser::Source::Buffer.new('<code>', 1)
      buffer.source = example.text
      parser = Parser::Ruby32.new(RuboCop::AST::Builder.new)
      parser.diagnostics.all_errors_are_fatal = true
      parser.parse(buffer)
    rescue Parser::SyntaxError => e
      path = example.object.file
      puts "#{path}: Syntax Error in an example. #{e}"
      ok = false
    end
  end
  abort unless ok
end
