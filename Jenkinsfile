pipeline {
  agent any
  tools {
    maven '3.6.3'
  }
  stages {
    stage('Unit Test') {
      steps {
        sh 'mvn clean test'
      }
    }
    stage('Deploy Standalone') {
      steps {
        sh 'mvn deploy -P standalone -Dmule.home=/bin/mule'
      }
    }
  }
}  
