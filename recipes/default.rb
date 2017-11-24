#
# Cookbook Name:: fileops
# Recipe:: default
#
# Copyright (c) 2017 The Authors, All Rights Reserved.

include_recipe "java"

# install grails
include_recipe "grails-cookbook"
grailsCmd = "JAVA_HOME=#{node.java.java_home} #{node['grails']['install_path']}/bin/grails"
fileopsRepo = "#{Chef::Config[:file_cache_path]}/Filesutra"
fileopsAdditionalConfig = "#{node.fileops.additional_config}"

bash 'cleanup extracted fileops' do
   code <<-EOH
   rm -rf #{node.fileops.extracted}
   rm -f #{fileopsAdditionalConfig}
   EOH
   action :nothing
   notifies :run, 'bash[unpack fileops]'
end

# download git repository zip
remote_file node.fileops.download do
  source   node.fileops.link
  mode     0644
  notifies :run, 'bash[cleanup extracted fileops]',:immediately
end

bash 'unpack fileops' do
  code <<-EOH
  cd "#{node.fileops.directory}"
  unzip  #{node.fileops.download}
  expectedFolderName=`basename #{node.fileops.extracted} | sed 's/.zip$//'`
  folderName=`basename #{node.fileops.download} | sed 's/.zip$//'`

  if [ "$folderName" != "$expectedFolderName" ]; then
      mv "$folderName" "$expectedFolderName"
  fi

  EOH
  not_if "test -d #{node.fileops.extracted}"
  notifies :create, "template[#{fileopsAdditionalConfig}]",:immediately
#  notifies :run, "bash[copy static files]",:immediately
end

bash "compile_fileops" do
  code <<-EOH
  cd #{node.fileops.extracted}
  yes | #{grailsCmd} upgrade
  export FILESUTRA_CONFIG=#{fileopsAdditionalConfig}
  yes | #{grailsCmd} -Dgrails.env=kk war  #{node.fileops.war}
  chmod +r #{node.fileops.war}
  EOH

  not_if "test -f #{node.fileops.war}"
  only_if "test -f #{fileopsAdditionalConfig}"
  notifies :run, "bash[copy fileops additional config]", :immediately
end

bash "copy fileops additional config" do
 code <<-EOH
  mkdir -p /tmp/fileops-temp/WEB-INF/lib
  mkdir -p ~tomcat/.grails
  cp #{fileopsAdditionalConfig} ~tomcat/.grails
  cp #{fileopsAdditionalConfig} /tmp/fileops-temp/WEB-INF/lib
  cd /tmp/fileops-temp/
  jar -uvf #{node.fileops.war}  WEB-INF/lib
  chmod +r #{node.fileops.war}
  #rm -rf /tmp/fileops-temp
  EOH
 notifies :enable, "cerner_tomcat[#{node.fileops.tomcat_instance}]", :immediately
  action :nothing
end

#  create additional-config
template fileopsAdditionalConfig do
  source "fileops-config.groovy.erb"
  notifies :run, "bash[compile_fileops]"
  notifies :run, "bash[copy fileops additional config]"
end

cerner_tomcat node.fileops.tomcat_instance do
  version "7.0.54"
  web_app "fileops" do
    source "file://#{node.fileops.war}"
  end

  java_settings("-Xms" => "512m",
                "-D#{node.biodiv.appname}_CONFIG_LOCATION=".upcase => "#{node.biodiv.additional_config}",
                "-D#{node.fileops.appname}_CONFIG=".upcase => "#{node.fileops.additional_config}",
                "-Dlog4jdbc.spylogdelegator.name=" => "net.sf.log4jdbc.log.slf4j.Slf4jSpyLogDelegator",
                "-Dfile.encoding=" => "UTF-8",
                "-Dorg.apache.tomcat.util.buf.UDecoder.ALLOW_ENCODED_SLASH=" => "true",
                "-Xmx" => "4g",
                "-XX:PermSize=" => "512m",
                "-XX:MaxPermSize=" => "512m",
                "-XX:+UseParNewGC" => "")
end


