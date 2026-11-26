import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/app_logger.dart';
import '../models/electricity_model.dart';
import '../services/electricity_service.dart';

/// 宿舍配置：最多配置两个宿舍，逻辑与牛×5 一致。
class DormConfigScreen extends StatefulWidget {
  const DormConfigScreen({super.key});

  @override
  State<DormConfigScreen> createState() => _DormConfigScreenState();
}

class _SlotState {
  SavedElectricityRoom? saved;
  String? areaName;
  String? buildingName;
  ElectricityRoom? room;
  List<ElectricityBuilding> buildings = const [];
  List<ElectricityRoom> rooms = const [];
  bool loadingBuildings = false;
  bool loadingRooms = false;
}

class _DormConfigScreenState extends State<DormConfigScreen> {
  final _logger = AppLogger.instance;

  final List<_SlotState> _slots = [_SlotState(), _SlotState()];
  List<ElectricityArea> _areas = const [];

  int _expanded = 0;
  bool _loadingAreas = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    for (var slot = 0; slot < _slots.length; slot++) {
      final saved = await ElectricityService.instance.loadSavedRoom(slot: slot);
      if (!mounted) return;
      final state = _slots[slot];
      state.saved = saved;
      state.areaName = saved?.areaName;
      state.buildingName = saved?.buildingName;
      if (saved != null) _expanded = slot;
    }
    if (!mounted) return;
    setState(() {});

    await _loadAreas();
    for (var slot = 0; slot < _slots.length; slot++) {
      final state = _slots[slot];
      final area = state.areaName;
      final building = state.buildingName;
      if (area != null && building != null) {
        await _loadBuildings(slot, area, silent: true);
        await _loadRooms(
          slot,
          area,
          building,
          selectRoomId: state.saved?.roomId,
        );
      }
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

  Future<void> _loadBuildings(int slot, String areaName, {bool silent = false}) async {
    final state = _slots[slot];
    setState(() {
      state.loadingBuildings = true;
      if (!silent) {
        state.buildings = const [];
        state.rooms = const [];
        state.buildingName = null;
        state.room = null;
      }
    });
    try {
      final buildings =
          await ElectricityService.instance.getBuildings(areaName);
      if (!mounted) return;
      setState(() {
        state.buildings = buildings;
        state.loadingBuildings = false;
      });
    } catch (e) {
      _logger.w('Load electricity buildings failed: $e');
      if (!mounted) return;
      setState(() => state.loadingBuildings = false);
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _loadRooms(
    int slot,
    String areaName,
    String buildingName, {
    String? selectRoomId,
  }) async {
    final state = _slots[slot];
    setState(() => state.loadingRooms = true);
    try {
      final rooms = await ElectricityService.instance.getRooms(
        areaName,
        buildingName,
      );
      if (!mounted) return;
      setState(() {
        state.rooms = rooms;
        state.loadingRooms = false;
        if (selectRoomId != null) {
          for (final room in rooms) {
            if (room.id == selectRoomId) {
              state.room = room;
              break;
            }
          }
        }
      });
    } catch (e) {
      _logger.w('Load electricity rooms failed: $e');
      if (!mounted) return;
      setState(() => state.loadingRooms = false);
      _toast(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _pickArea(int slot) async {
    final state = _slots[slot];
    final names = _areas.map((e) => e.name).toList();
    final value = await _showPicker('选择校区', names, state.areaName);
    if (value == null || value == state.areaName) return;
    setState(() {
      state.areaName = value;
      state.buildingName = null;
      state.room = null;
    });
    await _loadBuildings(slot, value);
  }

  Future<void> _pickBuilding(int slot) async {
    final state = _slots[slot];
    final names = state.buildings.map((e) => e.name).toList();
    final value = await _showPicker('选择楼栋', names, state.buildingName);
    if (value == null || value == state.buildingName) return;
    setState(() {
      state.buildingName = value;
      state.room = null;
    });
    await _loadRooms(slot, state.areaName!, value);
  }

  Future<void> _pickRoom(int slot) async {
    final state = _slots[slot];
    final names = state.rooms.map((e) => e.name).toList();
    final roomName = await _showPicker('选择房间', names, state.room?.name);
    if (roomName == null) return;
    for (final room in state.rooms) {
      if (room.name == roomName) {
        setState(() => state.room = room);
        await _saveSlot(slot);
        break;
      }
    }
  }

  Future<void> _saveSlot(int slot) async {
    final state = _slots[slot];
    final area = state.areaName;
    final building = state.buildingName;
    final room = state.room;
    if (area == null || building == null || room == null) return;

    final saved = SavedElectricityRoom(
      areaName: area,
      buildingName: building,
      roomId: room.id,
      roomName: room.name,
      mertype: room.mertype,
    );
    await ElectricityService.instance.saveRoom(saved, slot: slot);
    if (!mounted) return;
    setState(() => state.saved = saved);
    _toast('宿舍 ${slot + 1} 已保存');
  }

  Future<void> _clearSlot(int slot) async {
    await ElectricityService.instance.clearRoom(slot: slot);
    if (!mounted) return;
    setState(() {
      final state = _slots[slot];
      state.saved = null;
      state.areaName = null;
      state.buildingName = null;
      state.room = null;
      state.buildings = const [];
      state.rooms = const [];
    });
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

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      appBar: AppBar(title: const Text('宿舍配置')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          for (var slot = 0; slot < _slots.length; slot++) ...[
            if (slot > 0) const SizedBox(height: AppSpacing.md),
            _buildSlotCard(context, slot),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.lg),
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
        ],
      ),
    );
  }

  Widget _buildSlotCard(BuildContext context, int slot) {
    final c = context.colors;
    final state = _slots[slot];
    final expanded = _expanded == slot;

    final desc = state.saved == null
        ? '宿舍 ${slot + 1}（未选择）'
        : '${state.saved!.areaName} - ${state.saved!.buildingName} - ${state.saved!.roomName}';

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.cardAll,
        border: Border.all(color: expanded ? c.brand : c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = slot),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.card,
                vertical: AppSpacing.card,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyDense.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: c.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.card,
                0,
                AppSpacing.card,
                AppSpacing.card,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '宿舍 ${slot + 1}',
                        style: AppText.caption.copyWith(
                          color: c.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (state.saved != null)
                        InkWell(
                          onTap: () => _clearSlot(slot),
                          borderRadius: AppRadius.innerAll,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  size: 14,
                                  color: c.textMuted,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  '清除',
                                  style: AppText.caption.copyWith(
                                    color: c.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildSelector(
                    context,
                    label: '校区',
                    value: state.areaName,
                    loading: _loadingAreas,
                    enabled: !_loadingAreas,
                    onTap: () => _pickArea(slot),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildSelector(
                    context,
                    label: '楼栋',
                    value: state.buildingName,
                    loading: state.loadingBuildings,
                    enabled: state.areaName != null && !state.loadingBuildings,
                    onTap: () => _pickBuilding(slot),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildSelector(
                    context,
                    label: '房间',
                    value: state.room?.name,
                    loading: state.loadingRooms,
                    enabled:
                        state.buildingName != null && !state.loadingRooms,
                    onTap: () => _pickRoom(slot),
                  ),
                ],
              ),
            ),
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
