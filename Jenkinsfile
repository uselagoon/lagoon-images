def skipRemainingStages = false

pipeline {
  agent { label 'lagoon-images' }
  environment {
    // configure build params
    SAFEBRANCH_NAME = env.BRANCH_NAME.replaceAll('%2F','-').replaceAll('[^A-Za-z0-9]+', '-').toLowerCase()
    SAFEBRANCH_AND_BUILDNUMBER = (env.SAFEBRANCH_NAME+env.BUILD_NUMBER).replaceAll('%2f','').replaceAll('[^A-Za-z0-9]+', '').toLowerCase();
    CI_BUILD_TAG = 'lagoon'.concat(env.SAFEBRANCH_AND_BUILDNUMBER.drop(env.SAFEBRANCH_AND_BUILDNUMBER.length()-26));
    NPROC = "${sh(script:'getconf _NPROCESSORS_ONLN', returnStdout: true).trim()}"
    SKIP_IMAGE_PUBLISH = credentials('SKIP_IMAGE_PUBLISH')
    SYNC_MAKE_OUTPUT = 'target'
  }

  stages {
    stage ('env') {
      steps {
        sh 'env'
      }
    }

    // in order to have the newest images from upstream (with all the security
    // updates) we clean our local docker cache on tag deployments
    // we don't do this all the time to still profit from image layer caching
    // but we want this on tag deployments in order to ensure that we publish
    // images always with the newest possible images.
    stage ('clean docker image cache') {
      when {
        buildingTag()
        expression {
            !skipRemainingStages
        }
      }
      steps {
        sh script: "docker image prune -af", label: "Pruning images"
      }
    }

    stage ('build and push images') {
      when {
        expression {
            !skipRemainingStages
        }
      }
      environment {
        PASSWORD = credentials('amazeeiojenkins-dockerhub-password')
      }
      steps {
        sh script: "make -j$NPROC -O build", label: "Building images"
        retry(3) {
          sh script: 'docker login -u amazeeiojenkins -p $PASSWORD', label: "Docker login"
          sh script: "make -O publish-testlagoon-images PUBLISH_PLATFORM_ARCH=linux/amd64 BRANCH_NAME=${SAFEBRANCH_NAME}", label: "Publishing built amd64 images to testlagoon/*"
        }
      }
    }

    stage ('show built images') {
      steps {
        sh 'docker image ls | grep ${CI_BUILD_TAG} | sort -u'
      }
    }

    stage ('prepare tests and images') {
      parallel {
        stage ('Copy examples down') {
          steps {
            sh script: "rm -rf tests || echo 'no tests directory to remove'"
            sh script: "git clone https://github.com/uselagoon/lagoon-examples.git tests"
            dir ('tests') {
              sh script: "git submodule sync && git submodule update --init"
              sh script: "mkdir -p ./all-images && cp ../helpers/*docker-compose.yml ./all-images/ && cp ../helpers/TESTING_*_dockercompose.md ./all-images/"
              sh script: "sed -i '/image: uselagoon/ s/uselagoon/${CI_BUILD_TAG}/' ./all-images/*-docker-compose.yml"
              sh script: "yarn install"
              sh script: "docker network inspect amazeeio-network >/dev/null || docker network create amazeeio-network"
            }
          }
        }
      }
    }

    stage ('running test suite') {
      steps {
        dir ('tests') {
          sh script: "docker buildx use default", label: "Ensure to use default builder"
          sh script: "grep -rl uselagoon . | xargs sed -i '/^FROM/ s/uselagoon/${CI_BUILD_TAG}/'"
          sh script: "grep -rl uselagoon . | xargs sed -i '/image: uselagoon/ s/uselagoon/${CI_BUILD_TAG}/'"
          sh script: "find . -maxdepth 2 -name docker-compose.yml | xargs sed -i -e '/###/d'"
          sh script: "TEST=./all-images/TESTING_base_images* yarn test", label: "Run base-images tests"
          sh script: "TEST=./all-images/TESTING_service_images* yarn test", label: "Run service-images tests"
          sh script: "yarn test:simple", label: "Run simple Drupal tests"
          sh script: "yarn test:advanced", label: "Run advanced Drupal tests"
        }
      }
    }

    stage ('build arm images and push all images to testlagoon/*') {
      when {
        expression {
            !skipRemainingStages
        }
      }
      environment {
        PASSWORD = credentials('amazeeiojenkins-dockerhub-password')
      }
      steps {
        retry(3) {
          timeout(time: 30, unit: 'MINUTES') {
            sh script: "make -j$NPROC -O build PLATFORM_ARCH=linux/arm64", label: "Building arm images"
          }
        }
        retry(3) {
          sh script: 'docker login -u amazeeiojenkins -p $PASSWORD', label: "Docker login"
          sh script: "timeout 12m make -O publish-testlagoon-images PUBLISH_PLATFORM_ARCH=linux/arm64,linux/amd64 BRANCH_NAME=${SAFEBRANCH_NAME}", label: "Publishing built images"
        }
      }
    }
    
    stage ('push images to testlagoon/* with :latest tag') {
       when {
        branch 'main'
        not {
          environment name: 'SKIP_IMAGE_PUBLISH', value: 'true'
        }
        expression {
            !skipRemainingStages
        }
      }
      environment {
        PASSWORD = credentials('amazeeiojenkins-dockerhub-password')
      }
      steps {
        sh script: 'docker login -u amazeeiojenkins -p $PASSWORD', label: "Docker login"
        sh script: "make -O publish-testlagoon-images BRANCH_NAME=latest", label: "Publishing built images with :latest tag"
      }
    }

    stage ('push images to uselagoon/*') {
      when {
        buildingTag()
        not {
          environment name: 'SKIP_IMAGE_PUBLISH', value: 'true'
        }
        expression {
            !skipRemainingStages
        }
      }
      environment {
        PASSWORD = credentials('amazeeiojenkins-dockerhub-password')
      }
      steps {
        sh script: 'docker login -u amazeeiojenkins -p $PASSWORD', label: "Docker login"
        sh script: "make -O publish-uselagoon-images", label: "Publishing built images to uselagoon"
      }
    }

    stage ('scan built images') {
      when {
        anyOf {
          branch 'main'
          buildingTag()
        }
        not {
          environment name: 'SKIP_IMAGE_PUBLISH', value: 'true'
        }
      }
      steps {
        sh script: 'make scan-images', label: "perform scan routines"
        sh script:  'find ./scans/*trivy* -type f | xargs tail -n +1', label: "Show Trivy vulnerability scan results"
        sh script:  'find ./scans/*grype* -type f | xargs tail -n +1', label: "Show Grype vulnerability scan results"
        sh script:  'find ./scans/*syft* -type f | xargs tail -n +1', label: "Show Syft SBOM results"
      }
    }
  }

  post {
    always {
      cleanup()
      deleteDir()
    }
    success {
      notifySlack('SUCCESS')
    }
    failure {
      notifySlack('FAILURE')
    }
    aborted {
      notifySlack('ABORTED')
    }
  }
}

def cleanup() {
  try {
    sh "cat build.*"
    sh "make docker-buildx-remove"
    sh "make clean"
  } catch (error) {
    echo "cleanup failed, ignoring this."
  }
}

def notifySlack(String buildStatus = 'STARTED') {
    // Build status of null means success.
    buildStatus = buildStatus ?: 'SUCCESS'

    def color

    if (buildStatus == 'STARTED') {
        color = '#68A1D1'
    } else if (buildStatus == 'SUCCESS') {
        color = '#BDFFC3'
    } else if (buildStatus == 'UNSTABLE') {
        color = '#FFFE89'
    } else {
        color = '#FF9FA1'
    }

    def msg = "${buildStatus}: `${env.JOB_NAME}` #${env.BUILD_NUMBER}:\n${env.BUILD_URL}"

    slackSend(color: color, message: msg)
}
