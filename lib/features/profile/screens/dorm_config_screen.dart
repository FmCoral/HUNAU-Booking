import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/app_logger.dart';
import '../models/electricity_model.dart';
import '../services/electricity_service.dart';

/// 宿舍配置：选择校区、楼栋与房间，供「我」页展示电费余额。
class DormConfigScreen extends StatefulWidget {
  const DormConfigScreen({super.key});

  @override
  State<DormConfigScreen> createState() => _DormConfigScreenState();
}

class _DormConfigScreenState extends State<DormConfigScreen> {
  final _logger = AppLogger.instance;

  List<ElectricityArea> _areas = const [];
  List<ElectricityBuilding> _buildings = const [];
  List<ElectricityRoom> _rooms = const [];

  String? _areaName;
  String? _buildingName;
  ElectricityRoom? _room;

  SavedElectricityRoom? _saved;

  bool _loadingAreas = true;
  bool _loadingBuildings = false;
  bool _loadingRooms = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final saved = await ElectricityService.instance.loadSavedRoom();
    if (!mounted) return;
    setState(() {
      _saved = saved;
      _areaName = saved?.areaName;
      _buildingName = saved?.buildingName;
    });
    await _loadAreas();
    if (saved != null) {
      await _loadBuildings(saved.areaName, silent: true);
      await _loadRooms(
        saved.areaName,
        saved.buildingName,
        selectRoomId: saved.roomId,
      );
    }
  }

  Future<void> _loadAreas() async {
    setState(() {
      _loadingAreas = true;
      _error = null;
    });
    try {
      final areas = await ElectricityService.instance.getAreas();
      if (!mounted) return;
      setState(() {
        _areas = areas;
        _loadingAreas = false;
      });
    } catch (e) {
      _logger.w('Load electricity areas failed: $e');
      if (!mounted) return;
      setState(() {
        _loadingAreas = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadBuildings(String areaName, {bool silent = false}) async {
    setState(() {
      _loadingBuildings = true;
      if (!silent) {
        _buildings = const [];
        _rooms = const [];
        _buildingName = null;
        _room = null;
      }
    });
    try {
      final buildings =
          await ElectricityService.instance.getBuildings(areaName);
      if (!mounted) return;
      setState(() {
        _buildings = buildings;
        _loadingBuildings = false;
      });
    } catch (e) {
      _logger.w('Load electricity buildings failed: $e');
      if (!mounted) return;
      setState(() => _loadingBuildings = false);
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _loadRooms(
    String areaName,
    String buildingName, {
    String? selectRoomId,
  }) async {
    setState(() => _loadingRooms = true);
    try {
      final rooms = await ElectricityService.instance.getRooms(
        areaName,
        buildingName,
      );
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _loadingRooms = false;
        if (selectRoomId != null) {
          for (final room in rooms) {
            if (room.id == selectRoomId) {
              _room = room;
              break;
            }
          }
        }
      });
    } catch (e) {
      _logger.w('Load electricity rooms failed: $e');
      if (!mounted) return;
      setState(() => _loadingRooms = false);
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _pickArea() async {
    final names = _areas.map((e) => e.name).toList();
    final value = await _showPicker('选择校区', names, _areaName);
    if (value == null || value == _areaName) return;
    setState(() {
      _areaName = value;
      _buildingName = null;
      _room = null;
    });
    await _loadBuildings(value);
  }

  Future<void> _pickBuilding() async {
    final names = _buildings.map((e) => e.name).toList();
    final value = await _showPicker('选择楼栋', names, _buildingName);
    if (value == null || value == _buildingName) return;
    setState(() {
      _buildingName = value;
      _room = null;
    });
    await _loadRooms(_areaName!, value);
  }

  Future<void> _pickRoom() async {
    final names = _rooms.map((e) => e.name).toList();
    final roomName = await _showPicker('选择房间', names, _room?.name);
    if (roomName == null) return;
    for (final room in _rooms) {
      if (room.name == roomName) {
        setState(() => _room = room);
        break;
      }
    }
  }

  Future<String?> _showPicker(
    String title,
    List<String> options,
    String? current,
  ) {
    final c = context.colors;
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  title,
                  style: AppText.sectionTitle.copyWith(color: c.text),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final selected = option == current;
                    return ListTile(
                      title: Text(
                        option,
                        style: AppText.bodyDense.copyWith(
                          color: selected ? c.brandText : c.text,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      trailing: selected
                          ? Icon(Icons.check, size: 18, color: c.brand)
                          : null,
                      onTap: () => Navigator.pop(context, option),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    final area = _areaName;
    final building = _buildingName;
    final room = _room;
    if (area == null || building == null || room == null) {
      _toast('请选择完整的宿舍信息');
      return;
    }

    setState(() => _saving = true);
    try {
      await ElectricityService.instance.saveRoom(
        SavedElectricityRoom(
          areaName: area,
          buildingName: building,
          roomId: room.id,
          roomName: room.name,
          mertype: room.mertype,
        ),
      );
      if (!mounted) return;
      _toast('已保存');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString().replaceFirst('Exception: ', ''));
      setState(() => _saving = false);
    }
  }

  Future<void> _clear() async {
    await ElectricityService.instance.clearRoom();
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final saved = _saved;
    final canSave = _areaName != null &&
        _buildingName != null &&
        _room != null &&
        !_saving;

    return Scaffold(
      appBar: AppBar(title: const Text('宿舍配置')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          if (saved != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.card),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: AppRadius.cardAll,
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '当前宿舍',
                    style: AppText.caption.copyWith(
                      color: c.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${saved.areaName} ${saved.buildingName} ${saved.roomName}',
                    style: AppText.bodyDense.copyWith(
                      color: c.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Container(
            padding: const EdgeInsets.all(AppSpacing.card),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: AppRadius.cardAll,
              border: Border.all(color: c.border),
            ),
            child: Column(
              children: [
                _buildSelector(
                  context,
                  label: '校区',
                  value: _areaName,
                  loading: _loadingAreas,
                  enabled: !_loadingAreas,
                  onTap: _pickArea,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSelector(
                  context,
                  label: '楼栋',
                  value: _buildingName,
                  loading: _loadingBuildings,
                  enabled: _areaName != null && !_loadingBuildings,
                  onTap: _pickBuilding,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildSelector(
                  context,
                  label: '房间',
                  value: _room?.name,
                  loading: _loadingRooms,
                  enabled: _buildingName != null && !_loadingRooms,
                  onTap: _pickRoom,
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _error!,
              style: AppText.caption.copyWith(color: c.danger),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _loadAreas,
              child: const Text('重新加载'),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: canSave ? _save : null,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('保存'),
            ),
          ),
          if (saved != null) ...[
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: _saving ? null : _clear,
                style: TextButton.styleFrom(foregroundColor: c.danger),
                child: const Text('清除宿舍配置'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelector(
    BuildContext context, {
    required String label,
    required String? value,
    required bool loading,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final c = context.colors;
    return InkWell(
      borderRadius: AppRadius.controlAll,
      onTap: enabled ? onTap : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: enabled ? c.surfaceSubtle : c.surface,
          borderRadius: AppRadius.controlAll,
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: AppText.bodyDense.copyWith(color: c.textMuted),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                loading
                    ? '加载中...'
                    : (value?.isNotEmpty == true ? value! : '请选择'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AppText.bodyDense.copyWith(
                  color: value?.isNotEmpty == true ? c.text : c.textMuted,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: enabled ? c.textMuted : c.border,
            ),
          ],
        ),
      ),
    );
  }
}
