import QtQuick 2.9
import QtQuick.Controls 2.3

Dialog {
    id: dialog

    signal finished(string svgName,
                    string svgpath,
                    string svginking,
                    string svgfillcolor,
                    string svgtexture,
                    string svglighting,
                    string svgobjectAnimation,
                    string svgpathAnimation)

    function createSvgNode() {
        form.svgName.clear();
        form.svgpath.clear();
        form.svginking.clear();
        form.svgfillcolor.clear();
        form.svgtexture.clear();
        form.svglighting.clear();
        form.svgobjectAnimation.clear();
        form.svgpathAnimation.clear();

        dialog.title = qsTr("Add SVG Node");
        dialog.open();
    }

    function editSvgNode(svgNode) {
        form.svgName.text = svgNode.svgName;
        form.svgpath.text = svgNode.svgpath;
        form.svginking.text = svgNode.svginking;
        form.svgfillcolor.text = svgNode.svgfillcolor;
        form.svgtexture.text = svgNode.svgtexture;
        form.svglighting.text = svgNode.svglighting;
        form.svgobjectAnimation.text = svgNode.svgobjectAnimation;
        form.svgpathAnimation.text = svgNode.svgpathAnimation;

        dialog.title = qsTr("Edit SVG Node");
        dialog.open();
    }

//    x: parent.width / 2 - width / 2
//    y: parent.height / 2 - height / 2

    focus: true
    modal: true
    title: qsTr("Add SVG Node")
    standardButtons: Dialog.Ok | Dialog.Cancel

    contentItem: SvgForm {
        id: form
    }

    onAccepted: finished(form.svgName.text,
                         form.svgpath.text,
                         form.svginking.text,
                         form.svgfillcolor.text,
                         form.svgtexture.text,
                         form.svglighting.text,
                         form.svgobjectAnimation.text,
                         form.svgpathAnimation.text)
}
