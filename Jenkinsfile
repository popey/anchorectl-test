pipeline {
  environment {
    //
    // "REGISTRY" isn't required if we're using docker hub, I'm leaving it here in case you want to use a different registry
    REGISTRY = 'docker.io'
    //
    // you need a credential named 'docker-hub' with your DockerID/password to push images
    CREDENTIAL = "docker-hub"
    DOCKER_HUB = credentials("$CREDENTIAL")
    // this splits the credential into DOCKER_HUB_USR and DOCKER_HUB_PSW
    //
    REPOSITORY = "${DOCKER_HUB_USR}/${JOB_BASE_NAME}"
    BRANCH_NAME = "${GIT_BRANCH.split("/")[1]}"
    TAG = "${BRANCH_NAME}"
    //
    // IMAGELINE is what we pass to the Anchore Plugin
    IMAGELINE = "${REPOSITORY}:${TAG}"
    //
  } // end environment 
  
  agent any
  
  stages {
    
    stage('Checkout SCM') {
      steps {
        checkout scm
      } // end steps
    } // end stage "checkout scm"
    
    stage('Verify Tools') {
      steps {
        sh """
          which docker
          """
      } // end steps
    } // end stage "Verify Tools"
    
    stage('Build and Push Image') {
      steps {
        sh """
          echo ${DOCKER_HUB_PSW} | docker login -u ${DOCKER_HUB_USR} --password-stdin
          docker build -t ${REPOSITORY}:${TAG} --pull -f ./Dockerfile .
          docker push ${REPOSITORY}:${TAG}
        """
      } // end steps
    } // end stage "build and push"

    stage('Analyze Image w/ anchorectl') {
      environment {
        ANCHORECTL_URL = credentials("Anchorectl_Url")
        ANCHORECTL_USERNAME = credentials("Anchorectl_Username")
        ANCHORECTL_PASSWORD = credentials("Anchorectl_Password")
        // change ANCHORECTL_FAIL_BASED_ON_RESULTS to "true" if you want to break on policy violations
        ANCHORECTL_FAIL_BASED_ON_RESULTS = "false"
      }
      steps {
        script {
          sh """
            ### install anchorectl 
            curl -sSfL  https://anchorectl-releases.anchore.io/anchorectl/install.sh  | sh -s -- -b $HOME/.local/bin 
            export PATH="$HOME/.local/bin/:$PATH"          
            ###
            ### Notes:
            ###
            ### --wait tells anchorectl to block until the scan is complete (this isn't always necessary but if you want to pull 
            ### the vulnerability list and/or policy report, you probably want to wait
            ###
            ### --no-auto-subscribe tells the policy engine to just pull the image and scan it once.  if you don't pass this 
            ### option, anchore enterprise will continually poll the tag to see if any new version has been pushed and if 
            ### it detects a new image, it automatically pulls it and scans it.
            ###
            ### --force tells Anchore Enterprise to build a new SBOM even if one already exists in the catalog
            ###
            ### --dockerfile is optional but if you want to test Dockerfile instructions this is recommended
            ###
            ### --from registry tells anchorectl to analyze the image locally 
            #
            anchorectl image add --wait --dockerfile ./Dockerfile --from registry ${REGISTRY}/${REPOSITORY}:${TAG} 
            # 
            ### 
            ### if you want to do the traditional centralized scan, just leave off the --from option:
            ### anchorectl image add --wait --no-auto-subscribe --force --dockerfile ./Dockerfile ${REGISTRY}/${REPOSITORY}:${TAG}
            ###
            ### pull vulnerability list (optional)
            #
            anchorectl image vulnerabilities ${REGISTRY}/${REPOSITORY}:${TAG}
            #
            ###
            ### check policy evaluation
            #
            anchorectl image check --detail ${REGISTRY}/${REPOSITORY}:${TAG}
            #
            ### if you want to break the pipeline on a policy violation, add "--fail-based-on-results"
            ### to that "image check" or change the ANCHORECTL_FAIL_BASE_ON_RESULTS variable above to "true"
          """
        } // end script 
      } // end steps
    } // end stage "analyze with anchorectl"
    
    
    stage('Archive Evaluation with Anchore plugin') {
      steps {
        // anchore plugin for jenkins: https://www.jenkins.io/doc/pipeline/steps/anchore-container-scanner/
        //
        // first, we need to write out the "anchore_images" file which is what the plugin reads to know
        // which images to scan:
        writeFile file: 'anchore_images', text: IMAGELINE
        //
        // call the plugin
        anchore name: 'anchore_images', bailOnFail: false, engineRetries: '900'
      } // end steps
    } // end stage "analyze image 1 with anchore plugin"     
    
    // optional, you could promote the image here but I need to figure out how
    // to skip this stage if the eval failed since I'm using catchError
    //stage('Promote Image') {
    //  steps {
    //    sh """
    //      docker tag ${REPOSITORY}:${TAG} ${REPOSITORY}:production
    //      docker push ${REPOSITORY}:${BRANCH_NAME}
    //    """
    //  } // end steps
    //} // end stage "Promote Image"        
    
    stage('Clean up') {
      steps {
        //
        // don't need the image(s) anymore so let's rm it
        //
        sh 'docker image rm ${REPOSITORY}:${TAG} ${REPOSITORY}:production || failure=1'
        // the || failure=1 just allows us to continue even if one or both of the tags we're
        // rm'ing doesn't exist (e.g. if the evaluation failed, we might end up here without 
        // re-tagging the image, so ${BRANCH_NAME} wouldn't exist.
        //
      } // end steps
    } // end stage "clean up"
    
  } // end stages
  
} // end pipeline 
