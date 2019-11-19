import 'package:chaldea/generated/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChannels;

class InputCancelOkDialog extends StatefulWidget {
  final String title;
  final String text;
  final String hintText;
  final String errorText;
  final bool Function(String) validate;
  final void Function(String) onSubmit;

  const InputCancelOkDialog(
      {Key key,
      this.title,
      this.text,
      this.hintText,
      this.errorText,
      this.validate,
      this.onSubmit})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _InputCancelOkDialogState();
}

/// debug warnings:
/// W/IInputConnectionWrapper(31507): beginBatchEdit on inactive InputConnection
/// W/IInputConnectionWrapper(31507): getTextBeforeCursor on inactive InputConnection
/// W/IInputConnectionWrapper(31507): getTextAfterCursor on inactive InputConnection
/// W/IInputConnectionWrapper(31507): getSelectedText on inactive InputConnection
/// W/IInputConnectionWrapper(31507): endBatchEdit on inactive InputConnection
class _InputCancelOkDialogState extends State<InputCancelOkDialog> {
  TextEditingController _controller;
  bool validation = true;

  bool _validate(String v) {
    return widget.validate == null ? true : widget.validate(v);
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
  }

  @override
  Widget build(BuildContext context) {
    validation = _validate(_controller.text);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        autocorrect: false,
        decoration: InputDecoration(
            hintText: widget.hintText,
            errorText: validation ? null : "Invalid input."),
        onChanged: (v) {
          if (widget.validate != null) {
            setState(() {
              validation = _validate(v);
            });
          }
        },
        onSubmitted: (v) {
          SystemChannels.textInput.invokeMethod('TextInput.hide');
          widget.onSubmit(v);
          Navigator.pop(context);
        },
      ),
      actions: <Widget>[
        FlatButton(
          child: Text(S.of(context).cancel),
          onPressed: () => Navigator.pop(context),
        ),
        FlatButton(
          child: Text(S.of(context).ok),
          onPressed: () {
            String _value = _controller.text;
            validation = _validate(_value);
            setState(() {
              if (validation && widget.onSubmit != null) {
                widget.onSubmit(_value);
                Navigator.pop(context);
              }
            });
          },
        )
      ],
    );
  }
}

class SimpleCancelOkDialog extends StatelessWidget {
  final Widget title;
  final Widget content;
  final VoidCallback onTapOk;
  final VoidCallback onTapCancel;

  const SimpleCancelOkDialog(
      {Key key, this.title, this.content, this.onTapOk, this.onTapCancel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: title,
      content: content,
      actions: <Widget>[
        FlatButton(
          child: Text(S.of(context).cancel),
          onPressed: () {
            if (onTapCancel != null) {
              onTapCancel();
            }
            Navigator.pop(context);
          },
        ),
        if (onTapOk != null)
          FlatButton(
            child: Text(S.of(context).ok),
            onPressed: () {
              onTapOk();
            },
          )
      ],
    );
  }
}
