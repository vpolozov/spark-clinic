module Fhir
  class BundlePresenter
    def initialize(records)
      @records = Array(records)
    end

    def as_json(_opts = nil)
      {
        resourceType: "Bundle",
        type: "searchset",
        total: records.size,
        entry: records.map { |o| entry_for(o) }
      }
    end

    private

    attr_reader :records

    def entry_for(record)
      {
        fullUrl: "urn:uuid:#{record.id}",
        resource: Fhir::ObservationPresenter.new(record).as_json
      }
    end
  end
end
