import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!

    struct TouchPoint {
        var x: Float
        var z: Float
        var node: SCNNode

        func vector() -> SCNVector3 {
            return SCNVector3(x, node.position.y, z)
        }
    }

    private var touchPoint: TouchPoint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpSceneView()
        addTapGestureToSceneView()
        configureLighting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    private func setUpSceneView() {
        sceneView.delegate = self
        sceneView.showsStatistics = true
    }

    private func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)

        let planeNode = SCNNode(geometry: plane)
        planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor.clear

        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2

        node.addChildNode(planeNode)
    }

    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }

        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
        plane.firstMaterial?.diffuse.contents = UIColor.blue.withAlphaComponent(0.2)

        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
    }

    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.addShipToSceneView(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.didPress(recognizer:)))
        longPress.minimumPressDuration = 0.1
        sceneView.addGestureRecognizer(longPress)
    }

    @objc func didPress(recognizer: UILongPressGestureRecognizer) {
        let location = recognizer.location(in: sceneView)
        let hittest = sceneView.hitTest(location)
        if let node = hittest.first?.node {
            if recognizer.state == .began {
                let rotation = SCNAction.rotateBy(x: 0, y: CGFloat(2*CGFloat.pi), z: 0, duration: 1)
                let forever = SCNAction.repeatForever(rotation)
                node.runAction(forever)
            } else if recognizer.state == .ended {
                node.removeAllActions()
            }
        }
    }

    @objc func addShipToSceneView(withGestureRecognizer recognizer: UIGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)

        guard let hitTestResult = hitTestResults.first else { return }
        let translation = hitTestResult.worldTransform.columns.3
        let x = translation.x
        let y = translation.y + 0.122
        let z = translation.z

        guard let shipScene = SCNScene(named: "art.scnassets/iPad.scn"),
            let shipNode = shipScene.rootNode.childNode(withName: "iPad", recursively: false)
            else { return }
        shipNode.position = SCNVector3(x,y,z)
        sceneView.scene.rootNode.addChildNode(shipNode)
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
