require "pact_broker/matrix/reason"

module PactBroker
  module Api
    module Decorators
      class ReasonDecorator
        def initialize(reason)
          if reason.is_a?(PactBroker::Matrix::IgnoredReason)
            @reason = reason.root_reason
            @ignored = true
          else
            @reason = reason
            @ignored = false
          end
        end

        def to_s
          (ignored ? "Ignoring: " : "") + reason_text
        end

        private

        attr_reader :reason, :ignored

        # rubocop: disable Metrics/CyclomaticComplexity
        def reason_text
          case reason
          when PactBroker::Matrix::PactNotEverVerifiedByProvider
            "There is no verified pact between #{reason.consumer_selector.description} and #{reason.provider_selector.description}"
          when PactBroker::Matrix::PactNotVerifiedByRequiredProviderVersion
            "There is no verified pact between #{reason.consumer_selector.description} and #{reason.provider_selector.description}"
          when PactBroker::Matrix::SpecifiedVersionDoesNotExist
            version_does_not_exist_description(reason.selector)
          when PactBroker::Matrix::VerificationFailed
            "The verification for the pact between #{reason.consumer_selector.description} and #{reason.provider_selector.description} failed"
          when PactBroker::Matrix::NoDependenciesMissing
            "There are no missing dependencies"
          when PactBroker::Matrix::Successful
            "All required verification results are published and successful"
          when PactBroker::Matrix::InteractionsMissingVerifications
            descriptions = reason.interactions.collect do | interaction |
              interaction_description(interaction)
            end.join("; ")
            "WARN: Although the verification was reported as successful, the results for #{reason.consumer_selector.description} and #{reason.provider_selector.description} may be missing tests for the following interactions: #{descriptions}"
          when PactBroker::Matrix::IgnoreSelectorDoesNotExist
            "WARN: Cannot ignore #{reason.selector.description}"
          when PactBroker::Matrix::SelectorWithoutPacticipantVersionNumberSpecified
            "WARN: It is recommended to specify the version number (rather than the tag or branch) of the pacticipant you wish to deploy to avoid race conditions. Without a version number, this result will not be reliable."
          when PactBroker::Matrix::NoEnvironmentSpecified
            "WARN: It is recommended to specify the environment into which you are deploying. Without the environment, this result will not be reliable."
          else
            reason
          end
        end

        def version_does_not_exist_description selector
          if selector.version_does_not_exist?
            if selector.tag
              "No version with tag #{selector.tag} exists for #{selector.pacticipant_name}"
            elsif selector.pacticipant_version_number
              "No pacts or verifications have been published for version #{selector.pacticipant_version_number} of #{selector.pacticipant_name}"
            else
              "No pacts or verifications have been published for #{selector.pacticipant_name}"
            end
          else
            ""
          end
        end

        # TODO move this somewhere else
        def interaction_description(interaction)
          if interaction["providerState"] && interaction["providerState"] != ""
            "#{interaction['description']} given #{interaction['providerState']}"
          elsif interaction["providerStates"] && interaction["providerStates"].is_a?(Array) && interaction["providerStates"].any?
            provider_states = interaction["providerStates"].collect{ |ps| ps["name"] }.compact.join(", ")
            "#{interaction['description']} given #{provider_states}"
          else
            interaction["description"]
          end
        end
      end
      # rubocop: enable Metrics/CyclomaticComplexity
    end
  end
end
