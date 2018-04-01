import QtQuick 2.9
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3

Dialog {
    id: dialogShader
    
    signal finished(string propId,
                    string propParentId,
                    string propTypeName,
                    string propName,
                    string propData)
    
    function createNode(shaderNode) {
        //form.propId.clear();
        //Indiacate that it is a new node
        form.propId.text = -1;
        //Parent it to the current node
        //form.propParentId.clear();
        form.propParentId.text = shaderNode.treeId;
        form.propTypeName.clear();
        form.propName.clear();
        form.propData.clear();
        
        dialogShader.title = qsTr("Add Shader Node");
        dialogShader.open();
    }
    
    function editNode(shaderNode) {
        form.propId.text = shaderNode.treeId;
        form.propParentId.text = shaderNode.parentid;
        form.propTypeName.text = shaderNode.propTypeName;
        form.propName.text = shaderNode.propName;
        form.propData.text = shaderNode.propData;
        
        dialogShader.title = qsTr("Edit Shader Node");
        dialogShader.open();
    }
    
    x: parent.width / 2 - width / 2
    y: parent.height / 2 - height / 2
    
    focus: true
    modal: true
    title: qsTr("Add Shader Node")
    standardButtons: Dialog.Ok | Dialog.Cancel
    
    contentItem: GridLayout {
        id: form
        property alias propId: propId
        property alias propParentId: propParentId
        property alias propTypeName: propTypeName
        property alias propName: propName
        property alias propData: propData
        property int minimumInputSize: 120
        property string placeholderText: qsTr("<enter>")
        
        rows: 5
        columns: 2

        Label {
            id: propIdlogo
            text: "\uf1ae" + qsTr("Node Id:") // fa-child
            font.family: "fontawesome"
        }

        Label {
            id: propId
            text: qsTr("<Node Id>")
            Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        }

        Label {
            id: propParentIdlogo
            text: "\uf182" + qsTr("Node Parent Id:") // fa-female
            font.family: "fontawesome"
        }

        Label {
            id: propParentId
            text: qsTr("Node Parent")
            Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        }

        Label {
            text: qsTr("Node Type")
            Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        }
        
        TextField {
            id: propTypeName
            focus: true
            Layout.fillWidth: true
            Layout.minimumWidth: form.minimumInputSize
            Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
            placeholderText: form.placeholderText
        }
        
        Label {
            text: qsTr("Name:")
            Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        }
        
        TextField {
            id: propName
            Layout.fillWidth: true
            Layout.minimumWidth: form.minimumInputSize
            Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
            placeholderText: form.placeholderText
        }
        
        Label {
            text: qsTr("Data:")
            Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
        }
        
        TextField {
            id: propData
            Layout.fillWidth: true
            Layout.minimumWidth: form.minimumInputSize
            Layout.alignment: Qt.AlignLeft | Qt.AlignBaseline
            placeholderText: form.placeholderText
        }
        
    }
    
    onAccepted: finished(form.propId.text,
                         form.propParentId.text,
                         form.propTypeName.text,
                         form.propName.text,
                         form.propData.text)
}
