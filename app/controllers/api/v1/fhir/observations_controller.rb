class Api::V1::Fhir::ObservationsController < Api::BaseController

  # GET /api/v1/fhir/observations
  # Optional filters: patient_external_id, code, type
  def index
    observations = Observation.for_current_account.includes(:patient).recent
    if params[:patient_external_id].present?
      observations = observations.joins(:patient).where(patients: { external_id: params[:patient_external_id] })
    end
    observations = observations.where(code: params[:code]) if params[:code].present?
    observations = observations.with_kind(params[:type]) if params[:type].present?

    render json: Fhir::BundlePresenter.new(observations).as_json
  end

  # POST /api/v1/fhir/observations
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
