module MixedGauge
  # Mapping of slot -> connection_name.
  class ClusterConfig
    attr_reader :name, :connection_registry

    # @param [Symbol] name
    def initialize(name)
      @name = name
      @connection_registry = {}
    end

    # @param [Integer] size The slot size of this cluster.
    def define_slot_size(n)
      @slots = 0..(n - 1)
    end

    # @param [Range] assigned_slots The assigned range of slots of given
    #   connection (shard).
    # @param [Symbol] connection connection name
    def register(assigned_slots, connection)
      @connection_registry[assigned_slots] = connection
    end

    # @raise [RuntimeError]
    def validate_config!
      Validator.new(slot_size, @connection_registry).validate!
    end

    # @return [Integer]
    def slot_size
      defined?(@slot_size) ? @slot_size : @slot_size = @slots.size
    end

    # @param [Integer] slot
    # @return [Symbol] registered connection name
    def fetch(slot)
      @connection_registry.find { |slot_range, _name| slot_range.cover?(slot) }[1]
    end

    # @return [Array<Symbol>] An array of connection name
    def connections
      @connection_registry.values
    end

    # Validator
    class Validator
      # @param [Integer] slot_size
      # @param [Hash{Range => Symbol}] connection_registry
      def initialize(slot_size, connection_registry)
        @slot_size = slot_size
        @connection_registry = connection_registry
      end

      # @raise [RuntimeError]
      def validate!
        all_start_points = @connection_registry.keys.map(&:min).sort
        all_end_points = @connection_registry.keys.map(&:max).sort

        check_first_start_point(all_start_points.min)
        check_coverage(all_start_points, all_end_points)
        check_last_end_point(all_end_points.max)
      end

      private

      # @param [Integer] first_start_point
      def check_first_start_point(first_start_point)
        report_invalid_first_start_point(first_start_point) unless first_start_point.zero?
      end

      # @param [Array<Integer>] all_start_points
      # @param [Array<Integer>] all_end_points
      def check_coverage(all_start_points, all_end_points)
        all_end_points.each_with_index do |end_point, i|
          break if all_end_points.size == i + 1

          next_start_point = all_start_points[i + 1]
          report_invalid_coverage(end_point, all_start_points[i + 1]) unless end_point.succ == next_start_point
        end
      end

      # @param [Integer] last_end_point
      def check_last_end_point(last_end_point)
        report_invalid_last_end_point(last_end_point) unless last_end_point == @slot_size - 1
      end

      # @param [Integer] point
      def report_invalid_first_start_point(point)
        r = @connection_registry.keys.find { |range| range.min == point }
        connection = @connection_registry[r]
        raise "First start point must be `0` but given `#{point}`: invalid slot configuration for #{connection}"
      end

      # @param [Integer] end_point
      # @param [Integer] next_start_point
      # rubocop:disable Metrics/LineLength
      def report_invalid_coverage(end_point, next_start_point)
        end_point_slot = @connection_registry.keys.find { |range| range.max == end_point }
        end_point_connection = @connection_registry[end_point_slot]
        start_point_slot = @connection_registry.keys
                                               .find { |range| range.min == next_start_point && range.max != end_point }
        start_point_connection = @connection_registry[start_point_slot]

        raise %(End point `#{end_point}` of "#{end_point_connection}" or start point `#{next_start_point}` of "#{start_point_connection}" is invalid. Next start point must be "previous end point + 1".)
      end
      # rubocop:enable Metrics/LineLength

      # @param [Integer] point
      # rubocop:disable Metrics/LineLength
      def report_invalid_last_end_point(point)
        r = @connection_registry.keys.find { |range| range.max == point }
        connection = @connection_registry[r]
        raise "Last end point must be `#{@slot_size - 1}` but given `#{point}`: invalid slot configuration for #{connection}"
      end
      # rubocop:enable Metrics/LineLength
    end
  end
end
