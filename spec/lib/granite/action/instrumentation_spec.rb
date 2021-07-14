RSpec.describe Granite::Action::Instrumentation do
  def collect_payloads
    [].tap do |payloads|
      subscriber = ActiveSupport::Notifications.subscribe('granite.perform_action') do |_, _, _, _, payload|
        payloads << payload
      end

      yield

      ActiveSupport::Notifications.unsubscribe(subscriber)
    end
  end

  subject(:action) { DummyAction.new }

  before do
    stub_class(:DummyAction, Granite::Action) do
      allow_if { true }

      def execute_perform!(*)
      end
    end
  end

  it { expect(collect_payloads { action.perform! }).to eq([{action: action, using: :perform!}]) }
  it { expect(collect_payloads { action.perform }).to eq([{action: action, using: :perform}]) }
  it { expect(collect_payloads { action.try_perform! }).to eq([{action: action, using: :try_perform!}]) }
end
