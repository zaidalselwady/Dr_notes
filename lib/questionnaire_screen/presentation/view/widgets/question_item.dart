import 'package:flutter/material.dart';

import '../../../data/questionnaire_model.dart';

class QuestionItem extends StatelessWidget {
  final QuestionnaireModel questionModel;
  final ValueChanged<bool?> onChanged;

  const QuestionItem({
    super.key,
    required this.questionModel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        color: const Color(0xffB7E0FF).withOpacity(0.5),
        margin: const EdgeInsets.symmetric(vertical: 3.0),
        child: ListTile(
          leading: const Icon(Icons.tag_faces, color: Color(0xffE78F81)),
          title: Text(questionModel.question),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Radio<bool>(
                value: true,
                groupValue: questionModel.answer,
                onChanged: onChanged,
              ),
              const Text('Yes'),
              Radio<bool>(
                value: false,
                groupValue: questionModel.answer,
                onChanged: onChanged,
              ),
              const Text('No'),
            ],
          ),
        ),
      ),
    );
  }
}
