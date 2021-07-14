RSpec::Matchers.define :perform_action do |klass|
  chain :using do |using|
    @using = using
  end

  chain :as do |performer|
    @performer = performer
  end

  chain :with do |attributes|
    @attributes = attributes
  end

  match do |block|
    @klass = klass
    @using ||= :perform!

    @payloads = []
    subscriber = ActiveSupport::Notifications.subscribe('granite.perform_action') do |_, _, _, _, payload|
      @payloads << payload
    end

    block.call

    ActiveSupport::Notifications.unsubscribe(subscriber)

    @payload = @payloads.detect { |payload| payload[:action].is_a?(klass) && payload[:using] == @using }
    @payload && performer_matches? && attributes_match?
  end

  failure_message do
    if !@payload
      "#{expected_call} but it was not"
    elsif !performer_matches?
      "#{expected_call} as #{@performer.inspect} but it was called as #{action.performer.inspect}"
    elsif !attributes_match?
      "#{expected_call} with:\n#{@attributes.inspect}\nbut it was called with:\n#{actual_attributes.inspect}"
    end
  end

  failure_message_when_negated do
    "expected not to call #{performed_entity} but it was"
  end

  supports_block_expectations

  private

  def performed_entity
    "#{@klass}##{@using}"
  end

  def expected_call
    "expected to call #{performed_entity}"
  end

  def action
    @payload[:action]
  end

  def performer_matches?
    !defined?(@performer) || action.performer == @performer
  end

  def actual_attributes
    @actual_attributes ||= @attributes.keys.map { |attr| [attr, action.public_send(attr)] }.to_h
  end

  def attributes_match?
    !defined?(@attributes) || @attributes.all? { |attr, value| value == actual_attributes[attr] }
  end
end
