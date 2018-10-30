Given /^study "([^"]+)" has a registered sample "([^"]+)"$/ do |study_name, sample_name|
  study  = Study.find_by!(name: study_name)
  sample = study.samples.create!(name: sample_name)
  st = SampleTube.create!.tap { |sample_tube| sample_tube.aliquots.create!(sample: sample, study: study) }

  FactoryHelp::submission(
    study: study,
    assets: [st],
    state: 'ready'
  )
end
