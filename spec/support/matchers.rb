RSpec::Matchers.define :be_only_performed do |expected_options|
  match do |actual_job_class|
    raise ArgumentError, 'Need :times, and :period' unless [:times, :period].all? { |k| expected_options.keys.include? k }
    expected_period = expected_options[:period]
    expected_times = expected_options[:times]
    actual_job_class = actual_job_class.class unless actual_job_class.kind_of?(Class)
    unless actual_job_class.singleton_class.ancestors.include?(Resque::Plugins::WaitingRoom)
      raise ArgumentError, 'waiting room matcher used on non resque-job'
    end
    [actual_job_class.instance_variable_get(:@period) == expected_period,
    actual_job_class.instance_variable_get(:@max_performs) == expected_times].all?
  end

  failure_message do |actual_job_class|
    actual_times = actual_job_class.instance_variable_get(:@max_performs)
    actual_period = actual_job_class.instance_variable_get(:@period)
    "expected #{actual_job_class} to have defined can_be_performed times: #{expected_options[:times]} period: #{expected_options[:period]}, got can_be_performed times: #{actual_times} period: #{actual_times}"
  end

  failure_message_when_negated do |actual|
    "expected #{actual_job_class} to have NOT defined can_be_performed times: #{expected_options[:times]} period: #{expected_options[:period]}"
  end

  description do
    "be performed at most #{expected_options[:times]} in #{expected_options[:period]} seconds"
  end
end
