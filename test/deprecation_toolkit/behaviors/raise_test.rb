# frozen_string_literal: true

require "test_helper"

module DeprecationToolkit
  module Behaviors
    class RaiseTest < ActiveSupport::TestCase
      setup do
        @previous_configuration = Configuration.behavior
        Configuration.behavior = Raise
      end

      teardown do
        Configuration.behavior = @previous_configuration
      end

      test ".trigger raises an DeprecationIntroduced error when deprecations are introduced" do
        @expected_exception = DeprecationIntroduced

        ActiveSupport::Deprecation.warn("Foo")
        ActiveSupport::Deprecation.warn("Bar")
      end

      test ".trigger raises a DeprecationRemoved error when deprecations are removed" do
        @expected_exception = DeprecationRemoved

        ActiveSupport::Deprecation.warn("Foo")
      end

      test ".trigger raises a DeprecationRemoved when less deprecations than expected are triggerd and mismatches" do
        @expected_exception = DeprecationRemoved

        ActiveSupport::Deprecation.warn("C")
      end

      test ".trigger raises a DeprecationMismatch when same number of deprecations are triggered with mismatches" do
        @expected_exception = DeprecationMismatch

        ActiveSupport::Deprecation.warn("A")
      end

      test ".trigger does not raise when deprecations are triggered but were already recorded" do
        assert_nothing_raised do
          ActiveSupport::Deprecation.warn("Foo")
          ActiveSupport::Deprecation.warn("Bar")
        end
      end

      test ".trigger does not raise when deprecations are allowed with Regex" do
        @old_allowed_deprecations = Configuration.allowed_deprecations
        Configuration.allowed_deprecations = [/John Doe/]

        begin
          ActiveSupport::Deprecation.warn("John Doe")
          assert_nothing_raised { trigger_deprecation_toolkit_behavior }
        ensure
          Configuration.allowed_deprecations = @old_allowed_deprecations
        end
      end

      test ".trigger does not raise when deprecations are allowed with Procs" do
        class_eval <<-RUBY, "my_file.rb", 1337
          def deprecation_caller
            deprecation_callee
          end

          def deprecation_callee
            ActiveSupport::Deprecation.warn("John Doe")
          end
        RUBY

        old_allowed_deprecations = Configuration.allowed_deprecations
        Configuration.allowed_deprecations = [
          ->(_, stack) { stack.first.to_s =~ /my_file\.rb/ },
        ]

        begin
          deprecation_caller
          assert_nothing_raised { trigger_deprecation_toolkit_behavior }
        ensure
          Configuration.allowed_deprecations = old_allowed_deprecations
        end
      end

      test ".trigger does not raise when test is flaky" do
        assert_nothing_raised do
          ActiveSupport::Deprecation.warn("Foo")
          ActiveSupport::Deprecation.warn("Bar")
        end
      end

      def trigger_deprecation_toolkit_behavior
        super
        flunk if defined?(@expected_exception)
      rescue DeprecationIntroduced, DeprecationRemoved, DeprecationMismatch => e
        assert_equal(@expected_exception, e.class, e.message)
      end
    end
  end
end
