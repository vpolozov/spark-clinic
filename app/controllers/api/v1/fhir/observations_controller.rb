class Api::V1::Fhir::ObservationsController < Api::BaseController

  def create
    Observations::Fhir::IngestJob.perform_later(Current.account.id, params.to_unsafe_h)
    head :accepted
  end

  private

    def observation_params
      params.require(:observation)
            .permit(
              :patient_external_id, :type, :code, :recorded_at,
              :value, :unit,
              :systolic, :diastolic
            )
    end

end