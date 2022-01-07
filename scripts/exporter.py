from jinja2 import Environment, FileSystemLoader

if __name__ == "__main__":
    env = Environment(loader = FileSystemLoader('./templates'), trim_blocks=True, lstrip_blocks=True)
    templ = env.get_template('source.j2')
    file = open('./output.yml', 'w')
    currentPlat = ""
    with open('./contracts.txt') as f:
        lines = f.readlines()
        for line in lines:
            l = line.strip()
            if l.startswith("#"):
                currentPlat = l.strip("#")
                continue
            contract = l.split(" ")
            name = currentPlat+contract[0]
            address = contract[1]
            file.write(templ.render(name=name, address=address) +"\n")
            