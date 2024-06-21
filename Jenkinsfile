def skipRemainingStages = false

pipeline {
  agent { label 'lagoon-images' }
  environment {
    CI_BUILD_TAG = env.BUILD_TAG.replaceAll('%2f','').replaceAll("[^A-Za-z0-9]+", "").toLowerCase()
    SAFEBRANCH_NAME = env.BRANCH_NAME.replaceAll('%2f','-').replaceAll("[^A-Za-z0-9]+", "-").toLowerCase()
    SYNC_MAKE_OUTPUT = 'target'
    NPROC = "${sh(script:'getconf _NPROCESSORS_ONLN', returnStdout: true).trim()}"
  }

  stages {
    stage ('env') {
      steps {
        sh 'env'
      }
    }

    stage ('skip on docs commit') {
      when {
        anyOf {
          changeRequest branch: 'docs\\/.*', comparator: 'REGEXP'
          branch pattern: "docs\\/.*", comparator: "REGEXP"
        }
      }
      steps {
        script {
          skipRemainingStages = true
          echo "Docs only update, no build needed."
        }
      }
    }
    // in order to have the newest images from upstream (with all the security
    // updates) we clean our local docker cache on tag deployments
    // we don't do this all the time to still profit from image layer caching
    // but we want this on tag deployments in order to ensure that we publish
    // images always with the newest possible images.
    stage ('clean docker image cache') {
      when {
        branch 'main'
        buildingTag()
        expression {
            !skipRemainingStages
        }
      }
      steps {
        sh script: "make docker-buildx-remove", label: "removing leftover buildx"
        sh script: "docker image prune -af", label: "Pruning images"
        sh script: "docker buildx prune -af", label: "Pruning builder cache"
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
        sh script: "docker run --privileged --rm tonistiigi/binfmt --install all", label: "setting binfmt correctly"
        sh script: "make docker_pull", label: "Ensuring fresh upstream images"
        sh script: "make -O${SYNC_MAKE_OUTPUT} build", label: "Building images"
        retry(3) {
          sh script: 'docker login -u amazeeiojenkins -p $PASSWORD', label: "Docker login"
          sh script: "make -O${SYNC_MAKE_OUTPUT} publish-testlagoon-images PUBLISH_PLATFORM_ARCH=linux/amd64 BRANCH_NAME=${SAFEBRANCH_NAME}", label: "Publishing built amd64 images to testlagoon/*"
        }
      }
    }
    stage ('show built images') {
      when {
        expression {
            !skipRemainingStages
        }
      }
      steps {
        sh script: 'docker image ls | grep ${CI_BUILD_TAG} | sort -u', label: "show built images"
      }
    }
    stage ('Copy examples down') {
      when {
        expression {
            !skipRemainingStages
        }
      }
      steps {
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
    stage ('Test examples and testlagoon push') {
      when {
        expression {
            !skipRemainingStages
        }
      }
      parallel {
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
        stage ('push all images to testlagoon/*') {
          environment {
            PASSWORD = credentials('amazeeiojenkins-dockerhub-password')
          }
          steps {
            retry(3) {
              sh script: 'docker login -u amazeeiojenkins -p $PASSWORD', label: "Docker login"
              sh script: "timeout 15m make -O${SYNC_MAKE_OUTPUT} publish-testlagoon-images PUBLISH_PLATFORM_ARCH=linux/arm64,linux/amd64 BRANCH_NAME=${SAFEBRANCH_NAME}", label: "Publishing built images"
            }
          }
        }
      }
    }
    stage ('push images to testlagoon/* with :latest tag') {
       when {
        branch 'main'
        expression {
            !skipRemainingStages
        }
      }
      environment {
        PASSWORD = credentials('amazeeiojenkins-dockerhub-password')
      }
      steps {
        sh script: 'docker login -u amazeeiojenkins -p $PASSWORD', label: "Docker login"
        sh script: "timeout 15m make -O${SYNC_MAKE_OUTPUT} publish-testlagoon-images PUBLISH_PLATFORM_ARCH=linux/arm64,linux/amd64 BRANCH_NAME=latest", label: "Publishing built images with :latest tag"
      }
    }
    stage ('push images to uselagoon/*') {
      when {
        buildingTag()
        expression {
            !skipRemainingStages
        }
      }
      environment {
        PASSWORD = credentials('amazeeiojenkins-dockerhub-password')
      }
      steps {
        sh script: 'docker login -u amazeeiojenkins -p $PASSWORD', label: "Docker login"
        sh script: "make -O${SYNC_MAKE_OUTPUT} publish-uselagoon-images", label: "Publishing built images to uselagoon"
      }
    }
    stage ('scan built images') {
      when {
        anyOf {
          branch 'testing/scans'
          buildingTag()
        }
        expression {
            !skipRemainingStages
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
      sh "make docker-buildx-remove"
    }
    success {
      notifySlack('SUCCESS')
      deleteDir()
    }
    failure {
      notifySlack('FAILURE')
    }
    aborted {
      notifySlack('ABORTED')
    }
  }
}

def notifySlack(String status) {
  slackSend(
    color: ([STARTED: '#68A1D1', SUCCESS: '#BDFFC3', FAILURE: '#FF9FA1', ABORTED: '#949393'][status]),
    message: "${status}: `${env.JOB_NAME}` #${env.BUILD_NUMBER}:\n${env.BUILD_URL}")
}
