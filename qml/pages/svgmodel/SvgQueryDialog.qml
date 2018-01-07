import QtQuick 2.9
import QtQuick.Controls 2.3
import SvgUnderQML 1.0

Dialog {
    id: dialog

    SvgModel {
        id: svgModel
        onLoaded: {
            form.svgQuery.text = text
            form.svgFileName.text = svgModel.fileName
        }
        onEvaluated: {
            form.svgQueryOutput.text = text
        }
        onTypeSize: {
            if(count<1)
                typeId.visible = false
            else {
                typeId.visible = true
                typeId.to = count
                typeId.value = count
            }
        }
        onError: {
            form.svgQueryOutput.text = message
        }
    }

    signal finished(string svgFileName,
                    string svgQuery,
                    string svgQueryOutput,
                    string svgTypeIndex,
                    string typeId)

    function querySvgNode(fileUrl) {
        dialog.title = qsTr("Query SVG Node")
        dialog.open();
        svgModel.load(fileUrl)
    }

    x: parent.width / 2 - width / 2
    y: parent.height / 2 - height / 2

    focus: true
    modal: true
    title: qsTr("Query SVG Node")
    standardButtons: Dialog.Ok | Dialog.Cancel

    contentItem: SvgQueryForm {
        id: form
    }



    ComboBox {
        id: svgType
        editable: false
        model: ListModel {
            id: model
            ListElement { text: "file" }
            ListElement { text: "svg" }
            ListElement { text: "defs" }
            ListElement { text: "style" }
            ListElement { text: "pattern" }
            ListElement { text: "rect" }
            ListElement { text: "circle" }
            ListElement { text: "ellipse" }
            ListElement { text: "path" }
            ListElement { text: "g" }
            ListElement { text: "stylenode" }
        }
        onActivated: {
//            if (find(editText) === -1)
//                model.append({text: editText})
            svgModel.checkType(svgType.currentIndex);
        }
    }

    SpinBox {
        id: typeId
        from: 1
        to: 100
        value: 0
        editable: true
    }

    Button {
        id: button
        text: "Query Test"
        highlighted: true
        enabled: true
        onClicked: {
            svgModel.evaluateQuery(svgType.currentIndex,typeId.value)
        }
    }

    onAccepted: finished(form.svgFileName.text,
                         form.svgQuery.text,
                         form.svgQueryOutput.text,
                         svgType.currentIndex,
                         typeId.value)
}
