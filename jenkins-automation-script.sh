#!/bin/bash
sudo yum update -y
sudo yum install -y java-1.8.0-openjdk.x86_64
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
sudo yum install jenkins -y
sudo systemctl start jenkins.service
sudo systemctl enable jenkins.service
sudo mkdir /var/lib/jenkins/init.groovy.d
sudo chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d
sudo mkdir /var/lib/jenkins/init.groovy.d
sudo chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d
sudo touch /var/lib/jenkins/init.groovy.d/01-wizard.groovy
sudo touch /var/lib/jenkins/init.groovy.d/02-admin-user.groovy
sudo touch /var/lib/jenkins/init.groovy.d/03-plugins.groovy
sudo chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d/01-wizard.groovy
sudo chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d/02-admin-user.groovy
sudo chown -R jenkins:jenkins /var/lib/jenkins/init.groovy.d/03-plugins.groovy

sudo tee -a /var/lib/jenkins/init.groovy.d/01-wizard.groovy <<EOT
#!groovy

import jenkins.model.*
import hudson.util.*;
import jenkins.install.*;

def instance = Jenkins.getInstance()

instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)
EOT


sudo tee -a /var/lib/jenkins/init.groovy.d/02-admin-user.groovy <<EOT
/*
 * Create an admin user.
 */
import jenkins.model.*
import hudson.security.*

println "--> creating admin user"

//def adminUsername = System.getenv("ADMIN_USERNAME")
//def adminPassword = System.getenv("ADMIN_PASSWORD")

def adminUsername = "admin"
def adminPassword = "admin123"

assert adminPassword != null : "No ADMIN_USERNAME env var provided, but required"
assert adminPassword != null : "No ADMIN_PASSWORD env var provided, but required"

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount(adminUsername, adminPassword)
Jenkins.instance.setSecurityRealm(hudsonRealm)
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
Jenkins.instance.setAuthorizationStrategy(strategy)

Jenkins.instance.save()
EOT

sudo tee -a /var/lib/jenkins/init.groovy.d/03-plugins.groovy <<EOT
import jenkins.*
import hudson.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*
import hudson.plugins.sshslaves.*;
import hudson.model.*
import jenkins.model.*
import hudson.security.*

final List<String> REQUIRED_PLUGINS = [
        "workflow-aggregator",
        "ws-cleanup",
]

if (Jenkins.instance.pluginManager.plugins.collect {
  it.shortName
}.intersect(REQUIRED_PLUGINS).size() != REQUIRED_PLUGINS.size()) {
  REQUIRED_PLUGINS.collect {
    Jenkins.instance.updateCenter.getPlugin(it).deploy()
  }.each {
    it.get()
  }
  Jenkins.instance.restart()
  println 'Run this script again after restarting to create the jobs!'
  throw new RestartRequiredException(null)
}

println "Plugins were installed successfully"
EOT

sudo systemctl restart jenkins
sudo systemctl restart jenkins
