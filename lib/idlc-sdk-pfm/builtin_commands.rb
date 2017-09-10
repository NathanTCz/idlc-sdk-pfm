Pfm.commands do |c|
  c.builtin 'generate', :Generate, desc: 'Generate a new server build, repository, cookbooks, etc.'
  c.builtin 'build', :Build, desc: 'Build a specified server template'
  c.builtin 'validate', :Validate, desc: 'Test & validate a server build'
  c.builtin 'exec', :Exec, desc: 'Runs the command in context of the embedded ruby'
  c.builtin 'configure', :Configure, desc: 'Run initial setup and configuration'
  c.builtin 'plan', :Plan, desc: 'Show the infrastructure plan'
  c.builtin 'apply', :Apply, desc: 'Apply the infrastructure plan'
  c.builtin 'destroy', :Destroy, desc: 'Destroy all managed infrastructure'
  c.builtin 'format', :Format, desc: 'format infrastructure code'
end
