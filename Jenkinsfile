pipeline {
  agent any
  stages {
    stage('Unit Test') {
      steps {
        sh 'mvn clean test'
      }
    }
    stage('Deploy Standalone') {
      steps {
        sh 'mvn deploy -P standalone -Dmule.home=/opt/mule'
      }
    }
  }
}  
