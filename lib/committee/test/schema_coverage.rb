# frozen_string_literal: true

module Committee
  module Test
    class SchemaCoverage
      attr_reader :schema

      def initialize(schema)
        raise 'Unsupported schema' unless schema.is_a?(Committee::Drivers::OpenAPI3::Schema)

        @schema = schema
        @covered = {}
      end

      def update_response_coverage!(path, method, response_status)
        method = method.to_s.downcase
        response_status = response_status.to_s

        @covered[path] ||= {}
        @covered[path][method] ||= {}
        @covered[path][method]['responses'] ||= {}
        @covered[path][method]['responses'][response_status] = true
      end

      def report
        full = {}
        responses = []

        schema.open_api.paths.path.each do |path_name, path_item|
          full[path_name] = {}
          path_item._openapi_all_child_objects.each do |object_name, object|
            next unless object.is_a?(OpenAPIParser::Schemas::Operation)

            method = object_name.split('/').last&.downcase
            next unless method

            full[path_name][method] ||= {}

            # TODO: check coverage on request params/body as well?

            full[path_name][method]['responses'] ||= {}
            object.responses.response.each do |response_status, _|
              response_status = response_status.to_s
              is_covered = @covered.dig(path_name, method, 'responses', response_status) || false
              full[path_name][method]['responses'][response_status] = is_covered
              responses << {
                path: path_name,
                method: method,
                status: response_status,
                is_covered: is_covered,
              }
            end
          end
        end

        {
          full: full,
          responses: responses,
        }
      end
    end
  end
end

