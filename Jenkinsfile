node ('lagoon-images') {
  withEnv(['AWS_BUCKET=jobs.amazeeio.services', 'AWS_DEFAULT_REGION=us-east-2']) {
    withCredentials([
      usernamePassword(credentialsId: 'aws-s3-lagoon', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY'),
      string(credentialsId: 'SKIP_IMAGE_PUBLISH', variable: 'SKIP_IMAGE_PUBLISH')
    ]) {
      try {
        env.CI_BUILD_TAG = env.BUILD_TAG.replaceAll('%2f','').replaceAll("[^A-Za-z0-9]+", "").toLowerCase()
        env.SAFEBRANCH_NAME = env.BRANCH_NAME.replaceAll('%2f','-').replaceAll("[^A-Za-z0-9]+", "-").toLowerCase()
        env.SYNC_MAKE_OUTPUT = 'target'
        // make/tests will synchronise (buffer) output by default to avoid interspersed
        // lines from multiple jobs run in parallel. However this means that output for
        // each make target is not written until the command completes.
        //
        // See `man -P 'less +/-O' make` for more information about this option.
        //
        // Uncomment the line below to disable output synchronisation.
        // env.SYNC_MAKE_OUTPUT = 'none'

        stage ('env') {
          sh "env"
        }

        deleteDir()

        stage ('Checkout') {
          def checkout = checkout scm
          env.GIT_COMMIT = checkout["GIT_COMMIT"]
        }

        // in order to have the newest images from upstream (with all the security updates) we clean our local docker cache on tag deployments
        // we don't do this all the time to still profit from image layer caching
        // but we want this on tag deployments in order to ensure that we publish images always with the newest possible images.
        if (env.TAG_NAME || env.SAFEBRANCH_NAME == 'main') {
          stage ('clean docker image cache') {
            sh script: "make docker-buildx-remove", label: "removing leftover buildx"
            sh script: "docker image prune -af", label: "Pruning images"
            sh script: "docker buildx prune -af", label: "Pruning builder cache"
          }
        }

        stage ('build images') {
          sh script: "docker run --privileged --rm tonistiigi/binfmt --install all", label: "setting binfmt correctly"
          sh script: "make docker-buildx-configure", label: "Configuring buildx for multi-platform build"
          env.SCAN_IMAGES = 'true'
          sh script: "make docker_pull", label: "Ensuring fresh upstream images"
          sh script: "make -O${SYNC_MAKE_OUTPUT} -j8 build", label: "Building images"
        }

        stage ('show built images') {
          sh 'cat build.txt'
          sh 'docker image ls | grep ${CI_BUILD_TAG} | sort -u'
        }

        stage ('Copy examples down') {
          sh script: "git clone https://github.com/uselagoon/lagoon-examples.git tests"
          dir ('tests') {
            // sh script: "git submodule add -b php74 https://github.com/lagoon-examples/drupal9-postgres drupal9-postgres-php74"
            // sh script: "git submodule add -b php81 https://github.com/lagoon-examples/drupal9-base drupal9-base-php81"
            sh script: "git submodule sync && git submodule update --init"
            sh script: "mkdir -p ./all-images && cp ../helpers/*docker-compose.yml ./all-images/ && cp ../helpers/TESTING_*_dockercompose.md ./all-images/"
            sh script: "sed -i '/image: uselagoon/ s/uselagoon/${CI_BUILD_TAG}/' ./all-images/*-docker-compose.yml"
            sh script: "yarn install"
            sh script: "yarn generate-tests"
            sh script: "docker network inspect amazeeio-network >/dev/null || docker network create amazeeio-network"
          }
        }

        parallel (
          'build and push images to testlagoon dockerhub': {
            stage ('push branch images to testlagoon/*') {
              withCredentials([string(credentialsId: 'amazeeiojenkins-dockerhub-password', variable: 'PASSWORD')]) {
                try {
                  if (env.SKIP_IMAGE_PUBLISH != 'true') {
                    sh script: 'docker login -u amazeeiojenkins -p $PASSWORD', label: "Docker login"
                    sh script: "make -O${SYNC_MAKE_OUTPUT} -j8 publish-testlagoon-baseimages BRANCH_NAME=${SAFEBRANCH_NAME}", label: "Publishing built images to testlagoon"
                    if (env.SAFEBRANCH_NAME == 'main') {
                      sh script: "make -O${SYNC_MAKE_OUTPUT} -j8 build PUBLISH_IMAGES=true REGISTRY_ONE=testlagoon TAG_ONE=${SAFEBRANCH_NAME} REGISTRY_TWO=testlagoon TAG_TWO=latest", label: "Publishing built images to testlagoon main&latest images"
                    } else if (env.SAFEBRANCH_NAME == 'arm64-images') {
                      sh script: "make -O${SYNC_MAKE_OUTPUT} -j8 build PUBLISH_IMAGES=true REGISTRY_ONE=testlagoon TAG_ONE=${SAFEBRANCH_NAME} REGISTRY_TWO=testlagoon TAG_TWO=multiarch", label: "Publishing built images to testlagoon arm images"
                    } else {
                      sh script: 'echo "No multi-arch images required for this build"', label: "Skipping image publishing"
                    }
                  } else {
                    sh script: 'echo "skipped because of SKIP_IMAGE_PUBLISH env variable"', label: "Skipping image publishing"
                  }
                } catch (e) {
                  echo "Something went wrong, trying to cleanup"
                  cleanup()
                  throw e
                }
              }
            }
          },
          'Run all the tests on the local images': {
            stage ('running test suite') {
              dir ('tests') {
                sh script: "docker buildx use default", label: "Ensure to use default builder"
                sh script: "grep -rl uselagoon . | xargs sed -i '/^FROM/ s/uselagoon/${CI_BUILD_TAG}/'"
                sh script: "grep -rl uselagoon . | xargs sed -i '/image: uselagoon/ s/uselagoon/${CI_BUILD_TAG}/'"
                sh script: "find . -maxdepth 2 -name docker-compose.yml | xargs sed -i -e '/###/d'"
                sh script: "yarn test test/docker*base-images*", label: "Run base-images tests"
                sh script: "yarn test test/docker*service-images*", label: "Run service-images tests"
                sh script: "yarn test:simple", label: "Run simple Drupal tests"
                sh script: "yarn test:advanced", label: "Run advanced Drupal tests"
                sh script: "rm test/*.js"
              }
            }
          }
        )

        stage ('publish experimental image tags to testlagoon') {
          if (env.SAFEBRANCH_NAME == 'main' || env.CHANGE_ID && pullRequest.labels.contains("experimental")) {
            sh script: "make -O${SYNC_MAKE_OUTPUT} -j8 publish-testlagoon-experimental-baseimages BRANCH_NAME=${SAFEBRANCH_NAME}", label: "Publishing experimental images to testlagoon"
          } else {
            sh script: 'echo "not a PR or main branch push"', label: "Skipping experimantal image publishing"
          }
        }

        if (env.TAG_NAME && env.SKIP_IMAGE_PUBLISH != 'true') {
          parallel (
            'build and push images to uselagoon dockerhub': {
                stage ('push branch images to uselagoon/*') {
                  withCredentials([string(credentialsId: 'amazeeiojenkins-dockerhub-password', variable: 'PASSWORD')]) {
                    try {
                      if (env.SKIP_IMAGE_PUBLISH != 'true') {
                        sh script: 'docker login -u amazeeiojenkins -p $PASSWORD', label: "Docker login"
                        sh script: "make -O${SYNC_MAKE_OUTPUT} -j8 build PUBLISH_IMAGES=true REGISTRY_ONE=uselagoon TAG_ONE=${TAG_NAME} REGISTRY_TWO=uselagoon TAG_TWO=latest", label: "Publishing built images to uselagoon"
                      } else {
                        sh script: 'echo "skipped because of SKIP_IMAGE_PUBLISH env variable"', label: "Skipping image publishing"
                      }
                    } catch (e) {
                      echo "Something went wrong, trying to cleanup"
                      cleanup()
                      throw e
                    }
                  }
                }
            },
            'push legacy images to amazeeio dockerhub': {
              stage ('publish-amazeeio') {
                withCredentials([string(credentialsId: 'amazeeiojenkins-dockerhub-password', variable: 'PASSWORD')]) {
                  sh script: 'docker login -u amazeeiojenkins -p $PASSWORD', label: "Docker login"
                  sh script: "make -O${SYNC_MAKE_OUTPUT} -j8 publish-amazeeio-baseimages", label: "Publishing legacy images to amazeeio"
                }
              }
            }
          )
        }

        if (env.TAG_NAME || env.SAFEBRANCH_NAME == 'main' || env.SAFEBRANCH_NAME == 'testing-scans' ) {
          stage ('scan built images') {
            sh script: 'make scan-images', label: "perform scan routines"
            sh script:  'find ./scans/*trivy* -type f | xargs tail -n +1', label: "Show Trivy vulnerability scan results"
            sh script:  'find ./scans/*grype* -type f | xargs tail -n +1', label: "Show Grype vulnerability scan results"
            sh script:  'find ./scans/*syft* -type f | xargs tail -n +1', label: "Show Syft SBOM results"
          }
        }

      } catch (e) {
        currentBuild.result = 'FAILURE'
        echo "Something went wrong, trying to cleanup"
        throw e
      } finally {
        cleanup()
        notifySlack(currentBuild.result)
      }
      
      cleanup()
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
