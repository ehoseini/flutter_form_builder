import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:signature/signature.dart';

class FormBuilderSignaturePad extends StatefulWidget {
  final String attribute;
  final List<FormFieldValidator> validators;
  @Deprecated('There is currently no way of converting Uint8List to List<Point> - https://github.com/4Q-s-r-o/signature/issues/17.'
      'To Pass a list of points is initial value use `SignatureController`.')
  final Uint8List initialValue;
  final bool readOnly;
  final InputDecoration decoration;
  final ValueTransformer valueTransformer;
  final ValueChanged onChanged;
  final FormFieldSetter onSaved;

  @Deprecated('Set points within SignatureController')
  final List<Point> points;
  final double width;
  final double height;
  final Color backgroundColor;
  @Deprecated('Set penColor within SignatureController')
  final Color penColor;
  @Deprecated('Set penStrokeWidth within SignatureController')
  final double penStrokeWidth;
  final String clearButtonText;
  final SignatureController controller;

  FormBuilderSignaturePad({
    Key key,
    @required this.attribute,
    this.validators = const [],
    this.readOnly = false,
    this.decoration = const InputDecoration(),
    this.backgroundColor = Colors.white,
    this.penColor = Colors.black,
    this.penStrokeWidth = 3.0,
    this.clearButtonText = 'Clear',
    this.initialValue,
    this.points,
    this.width,
    this.height = 200,
    this.valueTransformer,
    this.onChanged,
    this.onSaved,
    this.controller,
  }) : super(key: key);

  @override
  _FormBuilderSignaturePadState createState() =>
      _FormBuilderSignaturePadState();
}

class _FormBuilderSignaturePadState extends State<FormBuilderSignaturePad> {
  bool _readOnly = false;
  Uint8List _initialValue;
  final GlobalKey<FormFieldState> _fieldKey = GlobalKey<FormFieldState>();
  FormBuilderState _formState;
  SignatureController _effectiveController;

  @override
  void initState() {
    _formState = FormBuilder.of(context);
    _formState?.registerFieldKey(widget.attribute, _fieldKey);
    _effectiveController = widget.controller ??
        SignatureController(
          // ignore: deprecated_member_use_from_same_package
          points: widget.controller?.points ?? widget.points,
          // ignore: deprecated_member_use_from_same_package
          penColor: widget.controller?.penColor ?? widget.penColor,
          penStrokeWidth:
              // ignore: deprecated_member_use_from_same_package
              widget.controller?.penStrokeWidth ?? widget.penStrokeWidth,
        );
    SchedulerBinding.instance.addPostFrameCallback((Duration duration) async {
      _initialValue = await _getControllerValue();
    });
    _effectiveController.addListener(() async {
      FocusScope.of(context).requestFocus(FocusNode());
      var value = await _getControllerValue();
      _fieldKey.currentState.didChange(value);
      widget.onChanged?.call(value);
    });
    super.initState();
  }

  Future<Uint8List> _getControllerValue() async {
    return await _effectiveController.toImage() != null
        ? await _effectiveController.toPngBytes()
        : null;
  }

  @override
  void dispose() {
    _formState?.unregisterFieldKey(widget.attribute);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _readOnly = _formState?.readOnly == true || widget.readOnly;

    return FormField<Uint8List>(
      key: _fieldKey,
      enabled: !_readOnly,
      initialValue: _initialValue,
      validator: (val) =>
          FormBuilderValidators.validateValidators(val, widget.validators),
      onSaved: (val) {
        var transformed;
        if (widget.valueTransformer != null) {
          transformed = widget.valueTransformer(val);
          _formState?.setAttributeValue(widget.attribute, transformed);
        } else {
          _formState?.setAttributeValue(widget.attribute, val);
        }
        if (widget.onSaved != null) {
          widget.onSaved(transformed ?? val);
        }
      },
      builder: (FormFieldState<dynamic> field) {
        return InputDecorator(
          decoration: widget.decoration.copyWith(
            enabled: !_readOnly,
            errorText: field.errorText,
          ),
          child: Column(
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: GestureDetector(
                  onVerticalDragUpdate: (_) {},
                  child: Signature(
                    width: widget.width,
                    height: widget.height,
                    backgroundColor: widget.backgroundColor,
                    controller: _effectiveController,
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(child: SizedBox()),
                  FlatButton.icon(
                    onPressed: () {
                      _effectiveController.clear();
                      field.didChange(null);
                    },
                    label: Text(
                      widget.clearButtonText,
                      style: TextStyle(color: Theme.of(context).errorColor),
                    ),
                    icon: Icon(
                      Icons.clear,
                      color: Theme.of(context).errorColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
