default[:fileops][:version]   = "master"
default[:fileops][:appname]   = "filesutra"
default[:fileops][:repository]   = "Filesutra"
default[:fileops][:directory] = "/usr/local/src"

default[:fileops][:link]      = "https://codeload.github.com/strandls/#{fileops.repository}/zip/#{fileops.version}"
default[:fileops][:extracted] = "#{fileops.directory}/fileops-#{fileops.version}"
default[:fileops][:war]       = "#{fileops.extracted}/target/fileops.war"
default[:fileops][:download]  = "#{fileops.directory}/#{fileops.repository}-#{fileops.version}.zip"

default[:fileops][:home] = "/usr/local/fileops"
default[:fileops][:tomcat_instance]    = "fileops"
default[:fileops][:additional_config] = "#{fileops.extracted}/#{node.fileops.appname}-config.groovy"

