# frozen_string_literal: true

require "date"

module RuboCop
  module Cop
    module NEETzsche
      class GeneratedMigrationTimestamp < Base
        include RangeHelp

        MSG = "Migration timestamp `%<timestamp>s` looks made up; %<tell>s. " \
              "Let `bin/rails generate migration` name the file."
        MSG_NO_TIMESTAMP = "Migration filename `%<basename>s` does not start with a 14-digit " \
                           "`YYYYMMDDHHMMSS_` timestamp. Let `bin/rails generate migration` name the file."

        VERSION_PREFIX = /\A\d+(?=_)/.freeze

        def on_new_investigation
          basename = File.basename(processed_source.file_path)
          digits = basename[VERSION_PREFIX]
          message = if digits&.length == 14
                      made_up_message(digits)
                    else
                      format(MSG_NO_TIMESTAMP, basename: basename)
                    end

          add_offense(first_character, message: message) if message
        end

        private

        def made_up_message(digits)
          tell = Timestamp.new(digits).tell
          format(MSG, timestamp: digits, tell: tell) if tell
        end

        def first_character
          source_range(processed_source.buffer, 1, 0)
        end

        class Timestamp
          PLACEHOLDERS = %w[123456 012345 102030 112233 153045 235959].freeze

          def initialize(digits)
            @digits = digits
            @year, @month, @day, @hour, @minute, @second = digits.unpack("a4a2a2a2a2a2").map(&:to_i)
          end

          def tell
            return "`#{date}` is not a real date" unless Date.valid_date?(@year, @month, @day)
            return "`#{clock}` is not a real time" unless real_time?
            return "`#{date}` is in the future" if Date.new(@year, @month, @day) > Time.now.utc.to_date

            clock_tell
          end

          private

          def clock_tell
            if round? then "`#{clock}` is a round clock time"
            elsif counter? then "`#{clock}` is a round hour plus a counter"
            elsif repeated? then "`#{clock}` repeats one number"
            elsif consecutive? then "`#{clock}` is three consecutive numbers"
            elsif placeholder? then "`#{clock}` is a placeholder time"
            end
          end

          def date
            "#{@digits[0, 4]}-#{@digits[4, 2]}-#{@digits[6, 2]}"
          end

          def clock
            "#{@digits[8, 2]}:#{@digits[10, 2]}:#{@digits[12, 2]}"
          end

          def real_time?
            @hour < 24 && @minute < 60 && @second < 60
          end

          def round?
            @second.zero? && (@minute % 5).zero?
          end

          def counter?
            return @minute.zero? || @second.zero? if @hour.zero?

            (@minute.zero? && @second < 10) || (@second.zero? && @minute < 10)
          end

          def repeated?
            @hour == @minute && @minute == @second
          end

          def consecutive?
            @minute == @hour + 1 && @second == @minute + 1
          end

          def placeholder?
            PLACEHOLDERS.include?(@digits[8, 6])
          end
        end
      end
    end
  end
end
