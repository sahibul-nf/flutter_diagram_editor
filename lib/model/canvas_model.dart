import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_provider_canvas/model/component_data.dart';
import 'package:flutter_provider_canvas/model/component_options_data.dart';
import 'package:flutter_provider_canvas/model/menu_data.dart';
import 'package:flutter_provider_canvas/model/port_connection.dart';
import 'package:flutter_provider_canvas/model/port_data.dart';
import 'package:flutter_provider_canvas/model/port_rules.dart';
import 'package:flutter_provider_canvas/user/component_body_1.dart';
import 'package:flutter_provider_canvas/user/component_body_2.dart';

import 'component_body.dart';
import 'custom_component_data.dart';
import 'item_selected.dart';
import 'link_data.dart';
import 'multiple_selection_option_data.dart';

int componentCount = 100;
int linkCount = 0;
int portPerComponentMaxCount = 4;
int menuComponentCount = 12;

class CanvasModel extends ChangeNotifier {
  int _componentIdGen = 0;
  int _linkIdGen = 0;

  Offset _position = Offset(0, 0);
  double _scale = 1.0;

  HashMap<String, ComponentBody> _componentBodyMap =
      HashMap<String, ComponentBody>();

  HashMap<int, ComponentData> _componentDataMap;
  HashMap<int, LinkData> _linkDataMap;
  MenuData menuData = MenuData();

  final double _portSize = 20;
  final double _optionSize = 40;

  dynamic selectedItem;
  final DeselectItem deselectItem = DeselectItem();

  final PortRules portRules = PortRules();

  bool isMultipleSelectionOn = false;
  List<int> selectedComponents = [];

  List<MultipleSelectionOptionData> multipleSelectionOptions = [];

  CanvasModel() {
    fillWithBodies();

    _componentDataMap = generateRandomComponents(componentCount);

    _linkDataMap = generateRandomLinks(linkCount);

    generatePortRules();

    menuData.addComponentsToMenu(
        generateRandomComponents(menuComponentCount, true).values.toList());

    multipleSelectionOptions = generateMultipleSelectedOptions();
  }

  Offset get position => _position;

  double get scale => _scale;

  HashMap<String, ComponentBody> get componentBodyMap => _componentBodyMap;

  HashMap<int, ComponentData> get componentDataMap => _componentDataMap;

  HashMap<int, LinkData> get linkDataMap => _linkDataMap;

  // ==== initializer ====

  addNewComponentBody(String name, ComponentBody body) {
    _componentBodyMap[name] = body;
  }

  // ==== NOTIFIERS ====

  addComponentToList(ComponentData componentData) {
    _componentDataMap[componentData.id] = componentData;
    notifyListeners();
  }

  removeComponentFromList(int id) {
    removeComponentConnections(id);

    _componentDataMap.remove(id);
    selectDeselectItem();
    notifyListeners();
  }

  duplicateComponent(int id, Offset offset) {
    int newId = generateNextComponentId;
    addComponentToList(_componentDataMap[id].duplicate(newId, offset));
  }

  duplicateComponentBelow(int id, Offset offset) {
    int newId = generateNextComponentId;
    addComponentToList(_componentDataMap[id].duplicate(
        newId, offset + Offset(0, _componentDataMap[id].size.height)));
  }

  removeComponentConnections(int id) {
    List<LinkData> linksToRemove = [];

    _componentDataMap[id].ports.values.forEach((port) {
      port.connections.forEach((connection) {
        linksToRemove.add(_linkDataMap[connection.connectionId]);
      });
    });

    linksToRemove.forEach(removeLink);
    notifyListeners();
  }

  resetCanvasView() {
    _position = Offset(0, 0);
    _scale = 1.0;
    notifyListeners();
  }

  updateCanvasPosition(Offset position) {
    _position += position;
  }

  updateCanvasScale(double scale) {
    _scale *= scale;
  }

  setCanvasData(Offset position, double scale) {
    _scale = scale;
    _position = position;
  }

  notifyCanvasModelListeners() {
    notifyListeners();
  }

  changeToRandomColor(int id) {
    _componentDataMap[id].color = randomColor();
    notifyListeners();
  }

  resizeComponent(int id) {
    _componentDataMap[id].switchEnableResize();
    selectDeselectItem();
    notifyListeners();
  }

  selectItem(dynamic item) {
    print('select item: $item');
    if (selectedItem == item) return;

    if (item == null) return;

    if (selectedItem != null) {
      selectedItem.isItemSelected = false;
    }

    if (item is ComponentData) {
    } else if (item is PortData) {
      if (selectedItem is PortData) {
        bool connected = tryToConnectTwoPorts(selectedItem, item);
        if (connected) {
          return;
        }
      }
    } else if (item is LinkData) {
    } else if (item is DeselectItem) {
    } else {
      throw ArgumentError("selected item is unknown type: $item");
    }

    selectedItem = item;
    selectedItem.isItemSelected = true;

    turnOffMultipleSelection();
    notifyListeners();
  }

  selectDeselectItem() {
    selectedItem = deselectItem;
  }

  bool tryToConnectTwoPorts(PortData firstPort, PortData secondPort) {
    if (canConnectTwoPorts(firstPort, secondPort)) {
      connectTwoPorts(firstPort, secondPort);
      selectDeselectItem();
      notifyListeners();
      return true;
    }
    return false;
  }

  bool canConnectTwoPorts(PortData firstPort, PortData secondPort) {
    if (!portRules.canConnect(firstPort.portType, secondPort.portType)) {
      return false;
    }
    if (arePortsConnected(firstPort, secondPort)) {
      return false;
    }
    if (!(hasLessThanMaxConnections(firstPort) &&
        hasLessThanMaxConnections(secondPort))) {
      return false;
    }
    if (!canConnectIfSameComponent(
        firstPort, secondPort, portRules.canConnectSameComponent)) {
      return false;
    }

    return true;
  }

  bool arePortsConnected(PortData firstPort, PortData secondPort) {
    int index = firstPort.connections.indexWhere((connection) =>
        connection.componentId == secondPort.componentId &&
        connection.portId == secondPort.id);
    return index >= 0;
  }

  bool hasLessThanMaxConnections(PortData port) {
    int max = portRules.getMaxConnectionCount(port.portType);
    if (max == null) {
      return true;
    } else {
      return port.connections.length < max;
    }
  }

  bool canConnectIfSameComponent(
      PortData firstPort, PortData secondPort, bool canConnectSame) {
    if (canConnectSame) {
      return true;
    } else {
      if (firstPort.componentId != secondPort.componentId) {
        return true;
      } else {
        return false;
      }
    }
  }

  connectTwoPorts(PortData portOut, PortData portIn) {
    print('connect two ports');
    generateNextLinkId;
    portOut.addConnection(
      PortConnectionOut(
        linkId: getLastUsedLinkId,
        componentId: portIn.componentId,
        portId: portIn.id,
      ),
    );
    portIn.addConnection(
      PortConnectionIn(
        linkId: getLastUsedLinkId,
        componentId: portOut.componentId,
        portId: portOut.id,
      ),
    );
    _linkDataMap[getLastUsedLinkId] = LinkData(
      id: getLastUsedLinkId,
      componentOutId: portOut.componentId,
      componentInId: portIn.componentId,
      color: Colors.black,
      width: 1.5,
      linkPoints: [
        componentDataMap[portOut.componentId].getPortCenterPoint(portOut.id),
        componentDataMap[portIn.componentId].getPortCenterPoint(portIn.id),
      ],
    );
  }

  removeLink(LinkData linkData) {
    linkDataMap.remove(linkData.id);
    componentDataMap[linkData.componentOutId].removeConnection(linkData.id);
    componentDataMap[linkData.componentInId].removeConnection(linkData.id);
    selectDeselectItem();
    notifyListeners();
  }

  void updateLinkMap(int componentId) {
    componentDataMap[componentId].ports.values.forEach((port) {
      port.connections.forEach((connection) {
        if (connection is PortConnectionOut) {
          linkDataMap[connection.connectionId].setStart(
              componentDataMap[componentId].getPortCenterPoint(port.id));
        } else if (connection is PortConnectionIn) {
          linkDataMap[connection.connectionId].setEnd(
              componentDataMap[componentId].getPortCenterPoint(port.id));
        } else {
          throw ArgumentError('Invalid port connection.');
        }
      });
    });
  }

  // ==== multiple selection ====

  switchMultipleSelection() {
    isMultipleSelectionOn = !isMultipleSelectionOn;
    selectDeselectItem();
    notifyListeners();
  }

  addToMultipleSelection(int componentId) {
    if (!selectedComponents.contains(componentId)) {
      selectedComponents.add(componentId);
      notifyListeners();
    }
  }

  addOrRemoveToMultipleSelection(int componentId) {
    if (!selectedComponents.remove(componentId)) {
      selectedComponents.add(componentId);
    }
    notifyListeners();
  }

  turnOffMultipleSelection() {
    isMultipleSelectionOn = false;
    selectedComponents = [];
  }

  clearMultipleSelectedComponents() {
    turnOffMultipleSelection();
    notifyListeners();
  }

  moveSelectedComponents(Offset position) {
    selectedComponents.forEach((componentId) {
      componentDataMap[componentId].updateComponentDataPosition(position);
      updateLinkMap(componentId);
    });
  }

  removeSelectedComponents() {
    selectedComponents.forEach((componentId) {
      removeComponentFromList(componentId);
    });
    clearMultipleSelectedComponents();
  }

  removeSelectedConnections() {
    selectedComponents.forEach((componentId) {
      removeComponentConnections(componentId);
    });
  }

  duplicateSelectedComponents() {
    print('duplicate');
    double mostTop = double.infinity;
    double mostBottom = double.negativeInfinity;
    selectedComponents.forEach((componentId) {
      if (mostTop > _componentDataMap[componentId].position.dy) {
        mostTop = _componentDataMap[componentId].position.dy;
      }
      if (mostBottom <
          _componentDataMap[componentId].position.dy +
              _componentDataMap[componentId].size.height) {
        mostBottom = _componentDataMap[componentId].position.dy +
            _componentDataMap[componentId].size.height;
      }
    });
    selectedComponents.forEach((componentId) {
      duplicateComponent(componentId, Offset(0, mostBottom - mostTop + 24));
    });
  }

  selectAllComponents() {
    _componentDataMap.keys.forEach((componentId) {
      addToMultipleSelection(componentId);
    });
  }

  // ==== functions all ====

  removeAllComponents() {
    clearMultipleSelectedComponents();
    var componentsToRemove = componentDataMap.keys.toList();
    componentsToRemove.forEach(removeComponentFromList);
  }

  removeAllConnections() {
    componentDataMap.values.forEach((component) {
      removeComponentConnections(component.id);
    });
  }

  // ==== IDs ==== TODO: improve

  int get generateNextComponentId => _componentIdGen++;

  int get getLastUsedComponentId => _componentIdGen - 1;

  int get getNextComponentId => _componentIdGen;

  int get generateNextLinkId => _linkIdGen++;

  int get getLastUsedLinkId => _linkIdGen - 1;

  int get getNextLinkId => _linkIdGen;

  // ==== HELPERS ====

  HashMap<int, ComponentData> generateRandomComponents(int number,
      [bool zeroPosition = false]) {
    HashMap<int, ComponentData> resultMap = HashMap<int, ComponentData>();

    for (int i = 0; i < number; i++) {
      int componentId = generateNextComponentId;
      resultMap[componentId] = ComponentData(
        id: componentId,
        color: randomColor(),
        size: Size(40 + 200 * math.Random().nextDouble(),
            40 + 120 * math.Random().nextDouble()),
        position: zeroPosition
            ? Offset.zero
            : Offset(1200 * 2 * (math.Random().nextDouble() - 0.5),
                1200 * 2 * (math.Random().nextDouble() - 0.5)),
        portSize: _portSize,
        ports: generatePortData(
            componentId, math.Random().nextInt(portPerComponentMaxCount + 1)),
        optionsData: ComponentOptionsData(
          optionSize: _optionSize,
          optionsTop: [
            ComponentOptionData(
              color: Colors.lime,
              icon: Icons.map,
              tooltip: "map",
              onOptionTap: (cid) {
                print('the correct on tap: $cid');
              },
            ),
            ComponentOptionData(),
            ComponentOptionData(tooltip: "nothing"),
          ],
          optionsBottom: [
            ComponentOptionData(
              color: Colors.red,
              icon: Icons.delete_forever,
              tooltip: "Delete",
              onOptionTap: (cid) {
                removeComponentFromList(cid);
                print('remove component: $componentId');
              },
            ),
            ComponentOptionData(
              color: Colors.yellow,
              icon: Icons.copy,
              tooltip: "Duplicate",
              onOptionTap: (cid) {
                duplicateComponentBelow(cid, Offset(0, 24));
                print('duplicate component: $cid');
              },
            ),
            ComponentOptionData(
              color: randomColor(),
              icon: Icons.color_lens_outlined,
              tooltip: "Change color randomly",
              onOptionTap: (cid) {
                changeToRandomColor(cid);
                print('change color: $cid');
              },
            ),
            ComponentOptionData(
              color: Colors.deepPurple,
              icon: Icons.link_off,
              tooltip: "Remove all connections",
              onOptionTap: (cid) {
                removeComponentConnections(cid);
                print('remove connections: $cid');
              },
            ),
            ComponentOptionData(
              color: Colors.deepOrange,
              icon: Icons.aspect_ratio,
              tooltip: "Resize",
              onOptionTap: (cid) {
                print("selected: ${_componentDataMap[cid].isItemSelected}");
                resizeComponent(cid);
                print('resize: $cid');
              },
            )
          ],
        ),
        customData: CustomComponentData(
          title: 'random title',
          description: 'loooong description',
        ),
        componentBodyName: math.Random().nextBool() ? 'body1' : 'body2',
      );
    }
    return resultMap;
  }

  HashMap<int, PortData> generatePortData(int componentId, int number) {
    HashMap<int, PortData> ports = HashMap<int, PortData>();
    for (int i = 0; i < number; i++) {
      ports[i] = PortData(
        id: i,
        componentId: componentId,
        color: randomColor(),
        borderColor: math.Random().nextBool() ? Colors.black : Colors.white,
        // alignment: Alignment(2 * math.Random().nextDouble() - 1,
        //     2 * math.Random().nextDouble() - 1),
        alignment: Alignment(math.Random().nextBool() ? 1 : -1,
            2 * math.Random().nextDouble() - 1),
        portType: math.Random().nextInt(4).toString(),
      );
    }
    return ports;
  }

  HashMap<int, LinkData> generateRandomLinks(int number) {
    HashMap<int, LinkData> resultMap = HashMap<int, LinkData>();
    for (int i = 0; i < number; i++) {
      generateNextLinkId;

      int idOut = math.Random().nextInt(getNextComponentId);
      int idIn = math.Random().nextInt(getNextComponentId);

      var componentOut = componentDataMap[idOut];
      var componentIn = componentDataMap[idIn];

      var portCountOut = componentOut.ports.length;
      if (portCountOut == 0) continue;
      var randomPortIdOut = math.Random().nextInt(portCountOut);

      var portCountIn = componentIn.ports.length;
      if (portCountIn == 0) continue;
      var randomPortIdIn = math.Random().nextInt(portCountIn);

      componentOut.ports[randomPortIdOut].addConnection(
        PortConnectionOut(
          linkId: getLastUsedLinkId,
          componentId: idOut,
          portId: randomPortIdOut,
        ),
      );

      componentIn.ports[randomPortIdIn].addConnection(
        PortConnectionIn(
          linkId: getLastUsedLinkId,
          componentId: idIn,
          portId: randomPortIdIn,
        ),
      );

      resultMap[getLastUsedLinkId] = LinkData(
        id: getLastUsedLinkId,
        componentOutId: idOut,
        componentInId: idIn,
        color: Colors.black,
        width: 1.5,
        linkPoints: [
          componentOut.getPortCenterPoint(randomPortIdOut),
          componentIn.getPortCenterPoint(randomPortIdIn),
        ],
      );
    }
    return resultMap;
  }

  Color randomColor() {
    return Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
        .withOpacity(1.0);
  }

  generatePortRules() {
    portRules.addRule("0", "1");
    portRules.addRule("0", "0");
    portRules.addRule("1", "1");
    portRules.addRules("2", ["0", "1"]);

    // portRules.canConnectSameComponent = true;

    portRules.setMaxConnectionCount("0", 2);
  }

  List<MultipleSelectionOptionData> generateMultipleSelectedOptions() {
    return [
      MultipleSelectionOptionData(
        icon: Icons.link_off,
        tooltip: "Delete connections",
        onOptionTap: removeSelectedConnections,
      ),
      MultipleSelectionOptionData(
        icon: Icons.delete_forever,
        tooltip: "Delete",
        onOptionTap: removeSelectedComponents,
      ),
      MultipleSelectionOptionData(
        icon: Icons.copy,
        tooltip: "Duplicate",
        onOptionTap: duplicateSelectedComponents,
      ),
      MultipleSelectionOptionData(
        icon: Icons.all_inclusive,
        tooltip: "Select all",
        onOptionTap: selectAllComponents,
      ),
    ];
  }

  fillWithBodies() {
    addNewComponentBody(
      "body1",
      ComponentBody(
        menuComponentBody: MenuComponentBodyWidget1(),
        componentBody: ComponentBodyWidget1(),
      ),
    );
    addNewComponentBody(
      "body2",
      ComponentBody(
        menuComponentBody: MenuComponentBodyWidget2(),
        componentBody: ComponentBodyWidget2(),
      ),
    );
  }
}
