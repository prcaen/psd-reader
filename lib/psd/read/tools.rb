module Psd
  module Read
    class Tools
      def self.padding_2(i)
        (i + 1).floor / 2 * 2;
      end

      def self.padding_4(i)
        i - (i % 4) + 3
      end

      def self.format_size(s)
        units = %W(B KiB MiB GiB TiB)

        size, unit = units.reduce(s.to_f) do |(fsize, _), utype|
          fsize > 512 ? [fsize / 1024, utype] : (break [fsize, utype])
        end

        "#{size > 9 || size.modulo(1) < 0.1 ? '%d' : '%.1f'} %s" % [size, unit]
      end

      def self.format_time_diff(start_time, end_time)
        diff = end_time - start_time

        if diff.floor == 0
          "#{(diff * 1000.0).round(2)}ms"
        else
          "#{diff.round(2)}s"
        end
      end
    end
  end
end
