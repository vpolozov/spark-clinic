class PatientsController < ApplicationController
  def index
    @patients = Patient.for_current_account.includes(:observations).order(:name)
  end

  def show
    @patient = Patient.for_current_account.find(params[:id])
    @observations = @patient.observations.recent
  end
end
