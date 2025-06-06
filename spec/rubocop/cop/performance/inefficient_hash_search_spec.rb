# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Performance::InefficientHashSearch, :config do
  shared_examples 'correct behavior' do |expected|
    let(:expected_key_method) { expected == :short ? 'key?' : 'has_key?' }
    let(:expected_value_method) { expected == :short ? 'value?' : 'has_value?' }

    it 'registers an offense when a hash literal receives `keys.include?`' do
      expect_offense(<<~RUBY)
        { a: 1 }.keys.include? 1
        ^^^^^^^^^^^^^^^^^^^^^^^^ Use `##{expected_key_method}` instead of `#keys.include?`.
      RUBY
    end

    it 'registers an offense when a hash literal receives `&.keys&.include?`' do
      expect_offense(<<~RUBY)
        { a: 1 }&.keys&.include? 1
        ^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `##{expected_key_method}` instead of `#keys.include?`.
      RUBY
    end

    it 'registers an offense when an existing hash receives `keys.include?`' do
      expect_offense(<<~RUBY)
        h = { a: 1 }; h.keys.include? 1
                      ^^^^^^^^^^^^^^^^^ Use `##{expected_key_method}` instead of `#keys.include?`.
      RUBY
    end

    it 'registers an offense when a hash literal receives `values.include?`' do
      expect_offense(<<~RUBY)
        { a: 1 }.values.include? 1
        ^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `##{expected_value_method}` instead of `#values.include?`.
      RUBY
    end

    it 'registers an offense when a hash variable receives `values.include?`' do
      expect_offense(<<~RUBY)
        h = { a: 1 }; h.values.include? 1
                      ^^^^^^^^^^^^^^^^^^^ Use `##{expected_value_method}` instead of `#values.include?`.
      RUBY
    end

    it 'finds no offense when a `keys` array variable receives `include?`' do
      expect_no_offenses(<<~RUBY)
        h = { a: 1 }; keys = h.keys ; keys.include? 1
      RUBY
    end

    it 'finds no offense when a `values` array variable receives `include?`' do
      expect_no_offenses(<<~RUBY)
        h = { a: 1 }; values = h.values ; values.include? 1
      RUBY
    end

    it 'does not register an offense when `keys` method defined by itself and `include?` method are method chaining' do
      expect_no_offenses(<<~RUBY)
        def my_include?(key)
          keys.include?(key)
        end
      RUBY
    end

    describe 'autocorrect' do
      context 'when using `keys.include?`' do
        it 'corrects to `key?` or `has_key?`' do
          new_source = autocorrect_source('{ a: 1 }.keys.include?(1)')
          expect(new_source).to eq("{ a: 1 }.#{expected_key_method}(1)")
        end

        it 'corrects when hash is not a literal' do
          new_source = autocorrect_source('h = { a: 1 }; h.keys.include?(1)')
          expect(new_source).to eq("h = { a: 1 }; h.#{expected_key_method}(1)")
        end

        it 'gracefully handles whitespace' do
          new_source = autocorrect_source("{ a: 1 }.  keys.\ninclude?  1")
          expect(new_source).to eq("{ a: 1 }.#{expected_key_method}(1)")
        end
      end

      context 'when using `values.include?`' do
        it 'corrects to `value?` or `has_value?`' do
          new_source = autocorrect_source('{ a: 1 }.values.include?(1)')
          expect(new_source).to eq("{ a: 1 }.#{expected_value_method}(1)")
        end

        it 'corrects when hash is not a literal' do
          new_source = autocorrect_source('h = { a: 1 }; h.values.include?(1)')
          expect(new_source).to eq("h = { a: 1 }; h.#{expected_value_method}(1)")
        end

        it 'gracefully handles whitespace' do
          new_source = autocorrect_source("{ a: 1 }.  values.\ninclude?  1")
          expect(new_source).to eq("{ a: 1 }.#{expected_value_method}(1)")
        end
      end
    end
  end

  it 'registers an offense when a hash literal receives `keys.include?` with safe navigation operator' do
    expect_offense(<<~RUBY)
      hash&.keys.include? 1
      ^^^^^^^^^^^^^^^^^^^^^ Use `#key?` instead of `#keys.include?`.
    RUBY

    expect_correction(<<~RUBY)
      hash&.key?(1)
    RUBY
  end

  it 'registers an offense when a hash literal receives `values.include?` with safe navigation operator' do
    expect_offense(<<~RUBY)
      hash&.values.include? 1
      ^^^^^^^^^^^^^^^^^^^^^^^ Use `#value?` instead of `#values.include?`.
    RUBY

    expect_correction(<<~RUBY)
      hash&.value?(1)
    RUBY
  end

  context 'when config is empty' do
    it_behaves_like 'correct behavior', :short
  end

  context 'when config enforces short hash methods' do
    let(:config) do
      RuboCop::Config.new(
        'AllCops' => {
          'Style/PreferredHashMethods' => {
            'EnforcedStyle' => 'short', 'Enabled' => true
          }
        }
      )
    end

    it_behaves_like 'correct behavior', :short
  end

  context 'when config specifies long hash methods but is not enabled' do
    let(:other_cops) do
      {
        'Style/PreferredHashMethods' => {
          'EnforcedStyle' => 'long', 'Enabled' => false
        }
      }
    end

    it_behaves_like 'correct behavior', :short
  end

  context 'when config enforces long hash methods' do
    let(:other_cops) do
      {
        'Style/PreferredHashMethods' => {
          'EnforcedStyle' => 'long', 'Enabled' => true
        }
      }
    end

    it_behaves_like 'correct behavior', :long
  end
end
