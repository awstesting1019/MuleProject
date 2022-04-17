pipeline {
  agent any
  tools {
    maven '3.8.1'
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
