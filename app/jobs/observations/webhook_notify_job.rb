require 'net/http'
require 'uri'

class Observations::WebhookNotifyJob < ApplicationJob
  queue_as :default

  retry_on StandardError, attempts: 3, wait: :exponentially_longer

  def perform(observation_id)
    observation = Observation.includes(:patient, :account).find(observation_id)
    url = observation.account.webhook_url.to_s
    return if url.blank?

    uri = URI.parse(url)
    payload = Fhir::ObservationPresenter.new(observation).as_json
    body = JSON.generate(payload)

    headers = {
      'Content-Type' => 'application/fhir+json; charset=utf-8',
      'User-Agent' => 'SparkClinic/1.0 Webhook'
    }

    Net::HTTP.post(uri, body, headers)
  end
end

