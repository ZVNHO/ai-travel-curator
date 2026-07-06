import 'package:flutter/material.dart';

class SettlementScreen extends StatefulWidget {
  const SettlementScreen({super.key});

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  final List<Map<String, dynamic>> personalExpenses = [];
  final List<Map<String, dynamic>> sharedExpenses = [];

  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _payerController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _peopleController = TextEditingController();

  String selectedView = '나의 지출';

  // 최적화된 계산기 관련 변수들
  String _calculatorDisplay = '0';
  String _currentOperation = '';
  double _firstOperand = 0;
  bool _waitingForOperand = false;

  int get personalTotal =>
      personalExpenses.fold(0, (sum, item) => sum + (item['amount'] as int));
  int get sharedTotal =>
      sharedExpenses.fold(0, (sum, item) => sum + (item['amount'] as int));
  int get mySharedTotal => sharedExpenses.fold(0, (sum, item) {
    final amount = item['amount'] as int? ?? 0;
    final people = item['people'] as int? ?? 1;
    return sum + (amount ~/ people);
  });
  int get totalAmount => personalTotal + sharedTotal;
  int get myTotal => personalTotal + mySharedTotal;

  void _openExpenseTypeDialog() {
    showDialog(
      context: context,
      builder:
          (_) => SimpleDialog(
            title: const Text("지출 유형 선택"),
            children: [
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  _openPersonalDialog();
                },
                child: const Text("개인 지출 추가"),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  _openSharedDialog();
                },
                child: const Text("공동 지출 추가"),
              ),
            ],
          ),
    );
  }

  void _openPersonalDialog({int? index}) {
    if (index != null) {
      _categoryController.text = personalExpenses[index]['category'];
      _amountController.text = personalExpenses[index]['amount'].toString();
    } else {
      _categoryController.clear();
      _amountController.clear();
    }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(index == null ? "개인 지출 추가" : "개인 지출 수정"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: "카테고리"),
                ),
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: "금액"),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("취소"),
              ),
              ElevatedButton(
                onPressed: () {
                  final category = _categoryController.text.trim();
                  final amount = int.tryParse(_amountController.text);
                  if (amount == null || category.isEmpty) {
                    _showErrorDialog("금액은 숫자, 카테고리는 필수입니다.");
                    return;
                  }
                  setState(() {
                    if (index == null) {
                      personalExpenses.add({
                        'category': category,
                        'amount': amount,
                        'color': Colors.orange,
                      });
                    } else {
                      personalExpenses[index] = {
                        'category': category,
                        'amount': amount,
                        'color': personalExpenses[index]['color'],
                      };
                    }
                  });
                  Navigator.pop(context);
                },
                child: Text(index == null ? "추가" : "수정"),
              ),
            ],
          ),
    );
  }

  void _openSharedDialog({int? index}) {
    if (index != null) {
      final item = sharedExpenses[index];
      _categoryController.text = item['category'];
      _payerController.text = item['payer'];
      _amountController.text = item['amount'].toString();
      _peopleController.text = item['people'].toString();
    } else {
      _categoryController.clear();
      _payerController.clear();
      _amountController.clear();
      _peopleController.clear();
    }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(index == null ? "공동 지출 추가" : "공동 지출 수정"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _categoryController,
                  decoration: const InputDecoration(labelText: "카테고리"),
                ),
                TextField(
                  controller: _payerController,
                  decoration: const InputDecoration(labelText: "지불자"),
                ),
                TextField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: "총 금액"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _peopleController,
                  decoration: const InputDecoration(labelText: "인원 수"),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("취소"),
              ),
              ElevatedButton(
                onPressed: () {
                  final category = _categoryController.text.trim();
                  final payer = _payerController.text.trim();
                  final amount = int.tryParse(_amountController.text);
                  final people = int.tryParse(_peopleController.text);
                  if (amount == null ||
                      people == null ||
                      category.isEmpty ||
                      payer.isEmpty) {
                    _showErrorDialog("모든 항목을 입력하고 금액/인원수는 숫자로 입력해주세요.");
                    return;
                  }
                  setState(() {
                    if (index == null) {
                      sharedExpenses.add({
                        'category': category,
                        'payer': payer,
                        'amount': amount,
                        'people': people,
                        'perPerson': (amount / people).floor(),
                        'color': _getColor(sharedExpenses.length),
                      });
                    } else {
                      sharedExpenses[index] = {
                        'category': category,
                        'payer': payer,
                        'amount': amount,
                        'people': people,
                        'perPerson': (amount / people).floor(),
                        'color': sharedExpenses[index]['color'],
                      };
                    }
                  });
                  Navigator.pop(context);
                },
                child: Text(index == null ? "추가" : "수정"),
              ),
            ],
          ),
    );
  }

  void _confirmDelete(bool isShared, int index) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("삭제 확인"),
            content: const Text("정말 삭제하시겠습니까?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("취소"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (isShared) {
                      sharedExpenses.removeAt(index);
                    } else {
                      personalExpenses.removeAt(index);
                    }
                  });
                  Navigator.pop(context);
                },
                child: const Text("삭제"),
              ),
            ],
          ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("입력 오류"),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("확인"),
              ),
            ],
          ),
    );
  }

  // 정산 결과 다이얼로그
  void _showSettlementDialog() {
    Map<String, int> payerTotals = {};

    // 각 지불자별 총 지불 금액 계산
    for (var expense in sharedExpenses) {
      String payer = expense['payer'];
      int perPersonAmount = expense['perPerson'];
      payerTotals[payer] = (payerTotals[payer] ?? 0) + perPersonAmount;
    }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("정산 결과"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "각 사람에게 보내야 할 금액:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...payerTotals.entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${entry.key}에게"),
                            Text(
                              "${_formatMoney(entry.value)}원",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("확인"),
              ),
            ],
          ),
    );
  }

  // 최적화된 계산기 다이얼로그
  void _showCalculator() {
    showDialog(
      context: context,
      builder:
          (context) => _CalculatorDialog(
            initialDisplay: _calculatorDisplay,
            initialOperation: _currentOperation,
            initialFirstOperand: _firstOperand,
            initialWaitingForOperand: _waitingForOperand,
            onClose: (display, operation, firstOperand, waitingForOperand) {
              // 다이얼로그가 닫힐 때 상태를 메인 위젯에 저장
              setState(() {
                _calculatorDisplay = display;
                _currentOperation = operation;
                _firstOperand = firstOperand;
                _waitingForOperand = waitingForOperand;
              });
            },
          ),
    );
  }

  Color _getColor(int index) {
    final colors = [Colors.blue, Colors.green, Colors.red, Colors.purple];
    return colors[index % colors.length];
  }

  String _formatMoney(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  Widget _buildExpenseBar(Map<String, dynamic> item, int index, bool isShared) {
    final percentage = totalAmount == 0 ? 0.0 : item['amount'] / totalAmount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                item['category'],
                style: const TextStyle(fontSize: 15),
              ),
            ),
            if (isShared)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "${item['payer']} 에게",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            IconButton(
              onPressed:
                  () =>
                      isShared
                          ? _openSharedDialog(index: index)
                          : _openPersonalDialog(index: index),
              icon: const Icon(Icons.edit, size: 20),
            ),
            IconButton(
              onPressed: () => _confirmDelete(isShared, index),
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(item['color']),
        ),
        if (isShared)
          Text(
            "1인당 부담: ${_formatMoney(item['perPerson'])}원",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
      ],
    );
  }

  // 빈 상태일 때 보여줄 위젯
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 40),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "아직 지출 내역이 없어요",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "여행이 완전히 끝나고 정산을 시작하세요\n첫 지출을 추가해보세요",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _openPersonalDialog,
                icon: const Icon(Icons.person, size: 18),
                label: const Text("개인 지출"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _openSharedDialog,
                icon: const Icon(Icons.group, size: 18),
                label: const Text("공동 지출"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    String title,
    int total,
    List<Map<String, dynamic>> data,
    bool isShared,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap:
                      () =>
                          isShared
                              ? _openSharedDialog()
                              : _openPersonalDialog(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, size: 16, color: Colors.grey[600]),
                  ),
                ),
                if (isShared && data.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: InkWell(
                      onTap: _showSettlementDialog,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.calculate,
                          size: 16,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Text(
              "${_formatMoney(total)}원",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (data.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text("아직 항목이 없습니다.", style: TextStyle(color: Colors.grey)),
          )
        else
          Column(
            children:
                data
                    .asMap()
                    .entries
                    .map((e) => _buildExpenseBar(e.value, e.key, isShared))
                    .toList(),
          ),
      ],
    );
  }

  Widget _buildSummaryHeader() {
    final displayAmount = selectedView == '총 지출' ? totalAmount : myTotal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButton<String>(
          value: selectedView,
          items:
              [
                '나의 지출',
                '총 지출',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (value) => setState(() => selectedView = value!),
        ),
        const SizedBox(height: 8),
        Text(
          "${_formatMoney(displayAmount)}원",
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyExpenses =
        personalExpenses.isNotEmpty || sharedExpenses.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("정산"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            _buildSummaryHeader(),
            if (!hasAnyExpenses)
              _buildEmptyState()
            else ...[
              _buildSection("개인 지출", personalTotal, personalExpenses, false),
              _buildSection("공동 지출", sharedTotal, sharedExpenses, true),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCalculator,
        backgroundColor: Colors.grey[700],
        child: const Icon(Icons.calculate, color: Colors.white),
      ),
    );
  }
}

// 별도의 계산기 다이얼로그 위젯
class _CalculatorDialog extends StatefulWidget {
  final String initialDisplay;
  final String initialOperation;
  final double initialFirstOperand;
  final bool initialWaitingForOperand;
  final Function(String, String, double, bool) onClose;

  const _CalculatorDialog({
    required this.initialDisplay,
    required this.initialOperation,
    required this.initialFirstOperand,
    required this.initialWaitingForOperand,
    required this.onClose,
  });

  @override
  State<_CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<_CalculatorDialog> {
  late String _calculatorDisplay;
  late String _currentOperation;
  late double _firstOperand;
  late bool _waitingForOperand;

  @override
  void initState() {
    super.initState();
    _calculatorDisplay = widget.initialDisplay;
    _currentOperation = widget.initialOperation;
    _firstOperand = widget.initialFirstOperand;
    _waitingForOperand = widget.initialWaitingForOperand;
  }

  void _inputNumber(String number) {
    setState(() {
      if (_waitingForOperand) {
        _calculatorDisplay = number;
        _waitingForOperand = false;
      } else {
        if (_calculatorDisplay == '0') {
          _calculatorDisplay = number;
        } else {
          _calculatorDisplay += number;
        }
      }
    });
  }

  void _inputOperation(String operation) {
    setState(() {
      if (_currentOperation.isNotEmpty && !_waitingForOperand) {
        _calculate();
      }

      _firstOperand = double.tryParse(_calculatorDisplay) ?? 0;
      _currentOperation = operation;
      _waitingForOperand = true;
    });
  }

  void _calculate() {
    setState(() {
      double secondOperand = double.tryParse(_calculatorDisplay) ?? 0;
      double result = 0;

      switch (_currentOperation) {
        case '+':
          result = _firstOperand + secondOperand;
          break;
        case '-':
          result = _firstOperand - secondOperand;
          break;
        case '×':
          result = _firstOperand * secondOperand;
          break;
        case '÷':
          result = secondOperand != 0 ? _firstOperand / secondOperand : 0;
          break;
      }

      if (result % 1 == 0) {
        _calculatorDisplay = result.toInt().toString();
      } else {
        _calculatorDisplay = result
            .toStringAsFixed(8)
            .replaceAll(RegExp(r'0*$'), '')
            .replaceAll(RegExp(r'\.$'), '');
      }

      _currentOperation = '';
      _waitingForOperand = true;
    });
  }

  void _clear() {
    setState(() {
      _calculatorDisplay = '0';
      _currentOperation = '';
      _firstOperand = 0;
      _waitingForOperand = false;
    });
  }

  void _handleButtonPress(String button) {
    switch (button) {
      case 'C':
      case 'CE':
        _clear();
        break;
      case '=':
        _calculate();
        break;
      case '+':
      case '-':
      case '×':
      case '÷':
        _inputOperation(button);
        break;
      case '%':
        setState(() {
          double value = double.tryParse(_calculatorDisplay) ?? 0;
          _calculatorDisplay = (value / 100).toString();
        });
        break;
      case '+/-':
        setState(() {
          double value = double.tryParse(_calculatorDisplay) ?? 0;
          _calculatorDisplay = (-value).toString();
        });
        break;
      default:
        _inputNumber(button);
    }
  }

  Widget _buildButtonRow(List<String> buttons) {
    return Expanded(
      child: Row(
        children:
            buttons
                .map(
                  (button) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: _buildCalculatorButton(
                        button,
                        () => _handleButtonPress(button),
                        isEquals: button == '=',
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildCalculatorButton(
    String text,
    VoidCallback onPressed, {
    bool isEquals = false,
  }) {
    return Material(
      color: isEquals ? Colors.blue : Colors.grey[200],
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 18,
              color: isEquals ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "계산기",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 60,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _calculatorDisplay,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
              child: Column(
                children: [
                  _buildButtonRow(['C', 'CE', '%', '÷']),
                  _buildButtonRow(['7', '8', '9', '×']),
                  _buildButtonRow(['4', '5', '6', '-']),
                  _buildButtonRow(['1', '2', '3', '+']),
                  _buildButtonRow(['+/-', '0', '.', '=']),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                widget.onClose(
                  _calculatorDisplay,
                  _currentOperation,
                  _firstOperand,
                  _waitingForOperand,
                );
                Navigator.pop(context);
              },
              child: const Text("닫기"),
            ),
          ],
        ),
      ),
    );
  }
}
