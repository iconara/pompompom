# encoding: utf-8

require 'java'

require_relative 'ext/ivy-2.3.0-rc1'


module Ivy
  import 'org.apache.ivy.Ivy'
  import 'org.apache.ivy.core.module.id.ModuleRevisionId'
  import 'org.apache.ivy.core.install.InstallOptions'
  import 'org.apache.ivy.plugins.resolver.FileSystemResolver'
  import 'org.apache.ivy.plugins.resolver.IBiblioResolver'
end

